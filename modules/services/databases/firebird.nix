{ config, pkgs, ... }:

# TODO review this all
# firebird 2.5 has a fb_config script in bin which shows that eg log still
# points to store

with pkgs.lib;

let

  cfg = config.services.firebird;

  firebird = cfg.package;

  pidFile = "${cfg.pidDir}/firebirdd.pid";

in

{

  ###### interface

  options = {

    services.firebird = {

      enable = mkOption {
        default = false;
        description = "
          Whether to enable the firebird super server.
        ";
      };

      package = mkOption {
        default = pkgs.firebirdSuper;
        description = "
          Which firebird derivation to use.
        ";
      };

      port = mkOption {
        default = "3050";
        description = "Port of Firebird";
      };

      user = mkOption {
        default = "firebird";
        description = "User account under which MySQL runs";
      };

      dataDir = mkOption {
        default = "/var/db/firebird/data"; # ubuntu is using /var/lib/firebird/2.1/data/.. ?
        description = "Location where firebird databases are stored";
      };

      # logError = mkOption {
      #   default = "/var/log/firebird_err.log";
      #   description = "Location of the MySQL error logfile";
      # };

      pidDir = mkOption {
        default = "/var/run/firebird";
        description = "Location of the file which stores the PID of the MySQL server";
      };

#       rootPassword = mkOption {
#         default = null;
#         description = "Path to a file containing the root password, modified on the first startup. Not specifying a root password will leave the root password empty.";
#       };

    };

  };


  ###### implementation

  config = mkIf config.services.firebird.enable {

    users.extraUsers = singleton
      { name = "firebird";
        description = "firebird server user";
      };

    environment.systemPackages = [firebird];

    jobs.firebird =
      { description = "firebird super server";

        startOn = "filesystem";

        preStart =
          ''
            # create data dir
            if ! test -e ${cfg.dataDir} /var/log/firebird; then
                mkdir -m 0700 -p ${cfg.dataDir} /var/log/firebird
                chown -R ${cfg.user} ${cfg.dataDir} /var/log/firebird
            fi

            secureDir=/var/db/firebird/system
            if ! test -e $secureDir/security2.fdb; then
                cp ${firebird}/security2.fdb $secureDir
                chown ${cfg.user} ${firebird}/security2.fdb
                chmod 700 ${cfg.user} ${firebird}/security2.fdb
            fi

            # create pid directory
            mkdir -m 0700 -p ${cfg.pidDir}
            chown -R ${cfg.user} ${cfg.pidDir}
          '';

        exec = ''${pkgs.su}/bin/su -s ${pkgs.bash}/bin/sh ${cfg.user} -c '${firebird}/bin/fbserver -d' '';
        # postStop = "${firebird}/bin/firebirdadmin ${optionalString (cfg.rootPassword != null) "--user=root --password=\"$(cat ${cfg.rootPassword})\""} shutdown";
        
        # !!! Need a postStart script to wait until firebirdd is ready to
        # accept connections.

        extraConfig = "kill timeout 60";
      };

      environment.etc =
        # think about this again - and eventually make it an option
        [ 
          { source = "${firebird}/firebird.msg";
            target = "firebird/firebird.msg";
          }
          { source = pkgs.writeText "firebird_config" ''
              # RootDirectory = Restrict ${cfg.dataDir}
              DatabaseAccess = Restrict ${cfg.dataDir}
              ExternalFileAccess = Restrict ${cfg.dataDir}
              # what is this? is None allowed?
              UdfAccess = None
              # "Native" =  traditional interbase/firebird, "mixed" is windows only
              Authentication = Native

              # defaults to -1 on non Win32
              #MaxUnflushedWrites = 100
              #MaxUnflushedWriteTime = 100

              # show trace if trouble occurs (does this require debug build?)
              # BugcheckAbort = 0
              # ConnectionTimeout = 180

              #RemoteServiceName = gds_db
              RemoteServicePort = ${cfg.port}

              # randomly choose port for server Event Notification
              #RemoteAuxPort = 0
              # rsetrict connections to a network card:
              #RemoteBindAddress =
              # there are some more settings ..
            '';
            target = "firebird/firebird.conf";
          }
        ];

  };

}
