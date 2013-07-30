{ config, pkgs, ... }:

# TODO: this file needs some additional work - at least you can connect to
# firebird ..
# Example how to connect:
# isql /var/db/firebird/data/your-db.fdb -u sysdba -p <default password>

# There are at least two ways to run firebird. superserver has been choosen
# however there are no strong reasons to prefer this or the other one AFAIK
# Eg superserver is said to be most efficiently using resources according to
# http://www.firebirdsql.org/manual/qsg25-classic-or-super.html

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
        /*
          Example: <code>package = pkgs.firebirdSuper.override { icu =
            pkgs.icu; };</code> which is not recommended for compatibility
            reasons. See comments at the firebirdSuper derivation
        */

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
        description = "User account under which firebird runs";
      };

      dataDir = mkOption {
        default = "/var/db/firebird/data"; # ubuntu is using /var/lib/firebird/2.1/data/.. ?
        description = "Location where firebird databases are stored";
      };

      pidDir = mkOption {
        default = "/run/firebird";
        description = "Location of the file which stores the PID of the firebird server";
      };

    };

  };


  ###### implementation

  config = mkIf config.services.firebird.enable {

    users.extraUsers = singleton
      { name = "firebird";
        description = "firebird server user";
      };

    environment.systemPackages = [firebird];

    systemd.services.firebird =
      { description = "firebird super server";

        wantedBy = [ "multi-user.target" ];

        # TODO: is it ok to move security2.fdb into the data directory?
        preStart =
          ''
            # create data dir
            if [ ! -e ${cfg.dataDir} -o ! -e /var/log/firebird ]; then
                mkdir -m 0700 -p ${cfg.dataDir} /var/log/firebird
                chown -R ${cfg.user} ${cfg.dataDir} /var/log/firebird
            fi

            # secureDir=/var/db/firebird/system
            secureDir=${cfg.dataDir}/../system
            if ! test -e $secureDir/security2.fdb; then
                mkdir -p -m 700 "$secureDir"
                cp ${firebird}/security2.fdb $secureDir
                chown ${cfg.user} $secureDir/security2.fdb
                chmod 700 $secureDir/security2.fdb
                chown -R ${cfg.user} $secureDir
            fi

            # create pid directory
            mkdir -m 0700 -p ${cfg.pidDir}
            chown -R ${cfg.user} ${cfg.pidDir}
          '';

        serviceConfig.ExecStart = ''${pkgs.su}/bin/su -s ${pkgs.bash}/bin/sh ${cfg.user} -c '${firebird}/bin/fbserver -d' '';

      };

    environment.etc."firebird/firebird.msg".source = "${firebird}/firebird.msg";

   # think about this again - and eventually make it an option
    environment.etc."firebird/firebird.conf".text = ''
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
    };

}
