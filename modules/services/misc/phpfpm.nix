{ config, pkgs, ... }:


let
  inherit (builtins) listToAttrs head baseNameOf unsafeDiscardStringContext toString;
  inherit (pkgs.lib) mkOption mkIf mkMerge mergeAttrs foldAttrs attrValues mapAttrs catAttrs fold maybeAttr;

  cfg =  config.services.phpfpm;

  phpFpmDaemons =

    let nv = name: value: listToAttrs [{ inherit name value; }];
        poolsWithIni = map (x: let hasPhpIni = x ? phpIni && x.phpIni != null; in
             x // {
              phpIniName = if hasPhpIni then baseNameOf (unsafeDiscardStringContext x.phpIni) else "";
              phpIni = if hasPhpIni then x.phpIni else null;
            }) cfg.pools;
        poolsByPHP = foldAttrs (n: a: [n] ++ a) [] (map (p: nv "${p.php.id}${p.phpIniName}" p) poolsWithIni);
        toDaemon = name: pools:
            let h = head pools;
            in h.php.system_fpm_config
             # daemon config
             {
               # TODO make option or such by letting user set these by php.id attr or such
               log_level = "notice";
               emergency_restart_threshold = "10";
               emergency_restart_interval = "1m";
               process_control_timeout = "5s";
               serviceName = "php-fpm-${maybeAttr "id" (h.php.id) h}";
               phpIni =  h.phpIni;
             }
             (map
              (p: 
               let socketPath = cfg.socketPathFun p;
               in p.pool
                  // { 
                  listen_address = socketPath;
                  name = builtins.baseNameOf socketPath;
                })
              pools);
    in attrValues (mapAttrs toDaemon poolsByPHP);

in {

  imports = [];

  options = {
    services.phpfpm = {
      enable = mkOption {
        default = true;
        description = "Whether to enable the PHP FastCGI Process Manager.";
      };

      stateDir = mkOption {
        default = "/var/run/phpfpm";
        description = "State directory with PID and socket files.";
      };

      logDir = mkOption {
        default = "/var/log/phpfpm";
        description = "Directory where to put in log files.";
      };

      socketPathFun = mkOption {
        description = "socketPathFun";
        default = pool:
          let php = pool.php;
          in if builtins ? hash
               then "/dev/shm/${php.id}-${builtins.hash "md5" (builtins.toXML (removeAttrs  pool.pool ["phpIni"]))}"
               else throw "bad: you need the hash patch for nixpkgs which can be found at github.com/MarcWeber/nix";
      };

      pools = mkOption {
        default = [];
        example = [
          rec {
            # php version, must support fpm
            php = pkgs.php5_2fpm.override {};

            id = "5.3"; # id of this 

            # note that most options can be set by using
            # php_flag[name]=on/off
            # php_admin_value[str_option]="127.0.0.1"
            # which should be preferred so that less php-fpm daemons have to be starteden-Source-Projekt: das ist die Idee des texanischen Tüftlers Ga
            # in extraLines pool config or the like
            # this only exists for php xdebug right now which has to be loaded
            # by php.ini, and that can't be configured in a pool, see
            # https://bugs.php.net/bug.php?id=54824
            #
            # phpIni is optional, can be set to null
            # phpIni = pkgs.runCommand "php.ini" { extraLines = "php ini lines"; }
            #   "cat ${php}/etc/php-recommended.ini > $out; echo \"$extraLines\" >> $out";

           # phpIni = if a ? xdebug
           #    then (pkgs.runCommand "php.ini" {
           #           extraLines = ''
           #             zend_extension="${php.xdebug}/lib/xdebug.so"
           #             zend_extension_ts="${php.xdebug}/lib/xdebug.so"
           #             zend_extension_debug="${php.xdebug}/lib/xdebug.so"
           #             xdebug.remote_enable=true
           #             xdebug.remote_host=127.0.0.1
           #             xdebug.remote_port=${builtins.toString a.xdebug.port}
           #             xdebug.remote_handler=dbgp
           #             xdebug.profiler_enable=0
           #             xdebug.profiler_output_dir="/tmp/xdebug"
           #             xdebug.remote_mode=req
           #           '';
           #           } "cat ${php}/etc/php-recommended.ini > $out; echo \"$extraLines\" >> $out")
           #    else null;

            pool = {
              # pool config, see system_fpm_config implementation in nixpkgs
              slowlog = ""; # must be writeable by the user/group of the php process?

              user = "user";
              group = "group";
              # listen_adress will be set automatically by socketPathFun
              listen = { owner = config.services.httpd.user; group = config.services.httpd.group; mode = "0700"; };

              pm = {
                value = "dynamic";
                max_children = 400;
                min_spare_servers = 10;
                max_spare_servers = 30;
              };
            };
          }
        ];

        description = ''
          Specify the pools the FastCGI Process Manager should manage.
          For each specific PHP and phpIni derivation combination a new
          php-fpm pool has to be created ..

          This is specified by using an attribute set which maps roughly 1:1
          to ini-file syntax, with the exception that the main value of a
          namespace has to be specified by an attribute called 'value'.

          In addition, attributes called 'env' or starting with 'php_' are
          formatted with square brackets, like for example 'env[TMP] = /tmp',
          which corresponds to 'env.TMP = "/tmp"'.

          The php-fpm daemon must run as root, because it must switch user for
          worker threads ..
        '';
      };
    };
  };

  # config = mkIf cfg.enable (mkMerge phpFpmDaemons);
  # is too strict, need to evaluate "config", so pick attrs which are used only
  config = {
    environment = mkMerge (catAttrs "environment" phpFpmDaemons);
    systemd.units = fold mergeAttrs {} (catAttrs "units" phpFpmDaemons);
    systemd.services = fold mergeAttrs {} (catAttrs "services" phpFpmDaemons);
  };
}
