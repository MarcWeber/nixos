{ config, pkgs, ... }:


let
  inherit (builtins) listToAttrs head baseNameOf unsafeDiscardStringContext toString;
  inherit (pkgs.lib) mkOption mkIf mkMerge mergeAttrs foldAttrs attrValues
                    mapAttrs catAttrs fold optionalString;

  cfg =  config.services.phpfpm;

  phpIniFile =
    {php, phpIniLines, name}:
      if phpIniLines == null
      then null # use whatever is default
      else (pkgs.runCommand name { }
        "cat ${php}/etc/php-recommended.ini > $out; echo \"$phpIniLines\" >> $out"
      );

  preparePool = pool:
    let
      enableXdebug = (pool.xdebug.enable or false);
      profileDir = pool.xdebug.profileDir or (id: "/tmp/xdebug-profiler-dir-${id}");
      xd = if enableXdebug
        then
          let remote_host = pool.xdebug.remote_host or "127.0.0.1";
              remote_port = builtins.toString pool.xdebug.remote_port or 9000;
          in {
            idAppend = "-xdebug";
            phpIniLines = ''
              remote_host = "${remote_host}";
              remote_port = ${remote_port};
            '';
          }
        else {
          idAppend = "";
          phpIniLines = "";
        };
      phpIniLines =
          xd.phpIniLines
          + pool.phpIniLines;


      # using phpIniLines create a cfg-id
      iniId = builtins.substring 0 5 (builtins.hash "sha256" phpIniLines)
              +xd.idAppend;

      phpIni = (pool.phpIniFile or phpIniFile) {
        inherit (pool) php;
        name = "php-${iniId}.ini";
        phpIniLines =
          (pool.phpIniLines or "")
          + optionalString enableXdebug "\nprofiler_output_dir = \"${profileDir iniId}\;";
      };

      id = "${pool.php.id}-${iniId}";
      hasPhpIni = phpIni == null;
      phpIniName = if hasPhpIni then baseNameOf (unsafeDiscardStringContext pool.phpIni) else "";
    in pool // { inherit phpIniName phpIni id; };


  phpFpmDaemons =

    let nv = name: value: listToAttrs [{ inherit name value; }];
        poolsWithIni = map preparePool cfg.pools;
        poolsByPHP = foldAttrs (n: a: [n] ++ a) [] (map (p: nv "${p.php.id}${p.phpIniName}" p) poolsWithIni);
        toDaemon = name: pools:
            let h = head pools;
            in h.php.system_fpm_config
                 { # daemon config
                   # TODO make option or such by letting user set these by php.id attr or such
                   log_level = "notice";
                   emergency_restart_threshold = "10";
                   emergency_restart_interval = "1m";
                   process_control_timeout = "5s";
                   jobName = "php-fpm-${h.php.id}";
                   phpIni =  h.phpIni;
                 }
                 # pools
                 (map (p:
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

      idFun = mkOption {
        description = "Function returning service name based on php compilation options, php ini file";
        default = pool: cfg.preparePool.id;
      };

      socketPathFun = mkOption {
        description = "Function returning socket path by pool to which web servers connect to.";
        default = pool: "/dev/shm/php-fpm-${cfg.idFun pool}";
      };

      pools = mkOption {
        default = [];
        example = [
          rec {
            # php version, must support fpm, thus must have a system_fpm_config attr
            php = pkgs.php5_2fpm.override {};

            # optional: append addditional php.ini lines.

            # Please note that most options can be set by using etxraLines in
            # the pool configuration like this:
            #   php_flag[name]=on/off
            #   php_admin_value[str_option]="127.0.0.1"
            # which should be preferred so that less php-fpm daemons have to be started
            phpIniLines = ''
            '';

            # optional: enable xdebug, if set additional phpIniLines will be created
            # xdebug can't be configured per pool, see: https://bugs.php.net/bug.php?id=54824
            xdebug = {
              enable = true;
              # optional names:
              # remote_host = "127.0.0.1";
              # remote_port = 9000;
              # profiler_output_dir = id: "/tmp/xdebug-profiler-dir-${id}";
            };

            # optional: override phpIniFile
            # phpIni = phpIniFile;

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
