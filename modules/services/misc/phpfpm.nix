{ config, pkgs, ... }:


let
  inherit (builtins) listToAttrs head baseNameOf unsafeDiscardStringContext toString;
  inherit (pkgs.lib) mkOption mkIf mkMerge mergeAttrs foldAttrs attrValues
                    mapAttrs catAttrs fold optionalString;

  cfg =  config.services.phpfpm;

  phpIniFile =
    {item, phpIniLines ? "", name}:
      pkgs.runCommand name { inherit phpIniLines; }
        "cat ${item.daemonCfg.php}/etc/php-recommended.ini > $out; echo \"$phpIniLines\" >> $out"
      ;

  preparePool = item: # item = item of phpfpm.pools
    let
      enableXdebug = item.daemonCfg.xdebug.enable or false;
      profileDir = item.daemonCfg.xdebug.profileDir or (id: "/tmp/xdebug-profiler-dir-${id}");
      xd = if enableXdebug
        then
          let remote_host = item.xdebug.remote_host or "127.0.0.1";
              remote_port = builtins.toString item.xdebug.remote_port or 9000;
           in {
             idAppend = "-xdebug";
             phpIniLines = ''
              zend_extension="${item.daemonCfg.php.xdebug}/lib/xdebug.so"
              zend_extension_ts="${item.daemonCfg.php.xdebug}/lib/xdebug.so"
              zend_extension_debug="${item.daemonCfg.php.xdebug}/lib/xdebug.so"
              xdebug.remote_enable=true
              xdebug.remote_host=${remote_host}
              xdebug.remote_port=${remote_port}
              xdebug.remote_handler=dbgp
              xdebug.profiler_enable=0
              xdebug.remote_mode=req
             '';
           }
        else {
          idAppend = "";
          phpIniLines = "";
        };
      phpIniLines =
          xd.phpIniLines
          + (item.phpIniLines or "");


      # using phpIniLines create a cfg-id
      iniId = builtins.substring 0 5 (builtins.hashString "sha256" (unsafeDiscardStringContext phpIniLines))
              +xd.idAppend;

      phpIni = (item.daemonCfg.phpIniFile or phpIniFile) {
        inherit item;
        name = "php-${iniId}.ini";
        phpIniLines =
          phpIniLines
          + optionalString enableXdebug "\nprofiler_output_dir = \"${item.daemonCfg.xdebug.profiler_output_dir or (profileDir iniId)}\;";
      };

      # [ID] see daemonIdFun
      id = item.daemonCfg.id or "${item.daemonCfg.php.id}-${iniId}";
      phpIniName = baseNameOf (unsafeDiscardStringContext item.phpIni);
    in item // {
        daemonCfg = item.daemonCfg // {
          inherit phpIniName phpIni id;
        };
      };


  phpFpmDaemons =

    let nv = name: value: listToAttrs [{ inherit name value; }];
        poolsWithIni = map preparePool cfg.pools;
        # group pools by common php and php ini config
        poolsByPHP = foldAttrs (n: a: [n] ++ a) [] (map (p: nv "${p.daemonCfg.id}" p) poolsWithIni);
        toDaemon = name: pools:
            let h = head pools;
            in h.daemonCfg.php.system_fpm_config
                 { # daemon config
                   # TODO make option or such by letting user set these by php.id attr or such
                   log_level = "notice";
                   emergency_restart_threshold = "10";
                   emergency_restart_interval = "1m";
                   process_control_timeout = "5s";
                   inherit (h.daemonCfg) id phpIni phpIniLines;
                 }
                 # pools
                 (map (p:
                   let socketPath = cfg.socketPathFun p;
                   in p.poolItemCfg
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

      daemonIdFun = mkOption {
        description = "Function returning service name based on php compilation options, php ini file";
        default = pool: (preparePool pool).daemonCfg.id;
      };

      socketPathFun = mkOption {
        description = "Function returning socket path by pool to which web servers connect to.";
        default = pool:
          let pool_h = builtins.substring 0 8 (builtins.hashString "sha256" (builtins.toXML pool.poolItemCfg));
          in "/dev/shm/php-fpm-${cfg.daemonIdFun pool}-${pool_h}";
      };

      pools = mkOption {
        default = [];
        example = [
          rec {

            ### php-fpm daemon options: If they differ multiple daemons will be started
            daemonCfg = {

              ### id
              # optional:
              # An ID based on the PHP configuration is generated automatically, see [ID] and daemonIdFun
              # id = "php-5.3"
              # this id is used to make the systemd units and the socket paths unique
              # see daemonIdFun etc.

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
                # profileDir = id: "/tmp/xdebug-profiler-dir-${id}"; # setting profiler_output_dir
              };

              # optional: override phpIniFile
              # phpIni = phpIniFile;
            };

            ### php-fpm per pool options
            poolItemCfg = {

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
    systemd = mkMerge (catAttrs "systemd" phpFpmDaemons);
  };
}
