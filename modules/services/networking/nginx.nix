{ config, pkgs, ... }:

with pkgs.lib;

let

  # very very quick implementation which should be reviewed..
  # what about -p prefix option?

  cfg = config.services.nginx;

  startingDependency = if config.services.gw6c.enable then "gw6c" else "network-interfaces";

  nginx = cfg.nginx;

  # TODO m make this more customizable
  nginxConf = logDir: pkgs.writeText "nginx-config.conf" ''
    # user  nobody;
    worker_processes  1;

    #error_log  logs/error.log;
    #error_log  logs/error.log  notice;
    #error_log  logs/error.log  info;

    #pid        logs/nginx.pid;


    events {
        worker_connections  1024;
    }


    http {
        include       mime.types;
        default_type  application/octet-stream;

        log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                          '$status $body_bytes_sent "$http_referer" '
                          '"$http_user_agent" "$http_x_forwarded_for"';

        #access_log  logs/access.log  main;
        access_log  ${logDir}/http_access.log  main;

        sendfile        on;
        #tcp_nopush     on;

        #keepalive_timeout  0;
        keepalive_timeout  65;

        #gzip  on;

        server {
            listen       ${builtins.toString cfg.port};
            server_name  ${cfg.server_name};

            #charset koi8-r;

            #access_log  logs/host.access.log  main;

            ${cfg.locations}

            # location / {
            #     root   html;
            #     index  index.html index.htm;
            # }

            #error_page  404              /404.html;

            # redirect server error pages to the static page /50x.html
            #
            error_page   500 502 503 504  /50x.html;
            location = /50x.html {
                root   html;
            }

            # proxy the PHP scripts to Apache listening on 127.0.0.1:80
            #
            #location ~ \.php$ {
            #    proxy_pass   http://127.0.0.1;
            #}

            # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
            #
            #location ~ \.php$ {
            #    root           html;
            #    fastcgi_pass   127.0.0.1:9000;
            #    fastcgi_index  index.php;
            #    fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
            #    include        fastcgi_params;
            #}

            # deny access to .htaccess files, if Apache's document root
            # concurs with nginx's one
            #
            #location ~ /\.ht {
            #    deny  all;
            #}
        }


        # another virtual host using mix of IP-, name-, and port-based configuration
        #
        #server {
        #    listen       8000;
        #    listen       somename:8080;
        #    server_name  somename  alias  another.alias;

        #    location / {
        #        root   html;
        #        index  index.html index.htm;
        #    }
        #}


        # HTTPS server
        #
        #server {
        #    listen       443;
        #    server_name  localhost;

        #    ssl                  on;
        #    ssl_certificate      cert.pem;
        #    ssl_certificate_key  cert.key;

        #    ssl_session_timeout  5m;

        #    ssl_protocols  SSLv2 SSLv3 TLSv1;
        #    ssl_ciphers  ALL:!ADH:!EXPORT56:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv2:+EXP;
        #    ssl_prefer_server_ciphers   on;

        #    location / {
        #        root   html;
        #        index  index.html index.htm;
        #    }
        #}

    }
  '';

  # nginx reads mime.types beneath nginx.conf
  nginxConfDir = logDir: pkgs.runCommand "nginx-conf-dir" {} ''
    ensureDir $out
    cp ${nginxConf logDir} $out/nginx.conf
    ln -s ${nginx}/conf/mime.types $out/mime.types
  '';

in
  
{

  ###### interface

  options = {
  
    services.nginx = {


      server_name = mkOption {
        default = "localhost";
        description = "servername";
      };

      nginx = mkOption {
        default = pkgs.nginx;
        description = "nginx derivation to be used";
      };

      port = mkOption {
        default = 80;
        description = "port to listen on";
      };
    
      enable = mkOption {
        default = false;
        description = "Whether to enable nginx.";
      };

      logDir = mkOption {
        default = "/var/log/nginx";
        description = "Extra hosts to be added";
      };

      locations = mkOption {
        default = "";
        description = "Extra hosts to be added";
      };

    };

  };


  ###### implementation

  config = mkIf cfg.enable {

    jobs.nginx =
      { # Statically verify the syntactic correctness of the generated
        # httpd.conf.  !!! this is impure!  It doesn't just check for
        # syntax, but also whether the Apache user/group exist,
        # whether SSL keys exist, etc.
        buildHook =
          ''
            echo
            echo '=== Checking the generated nginx configuration file ==='
            mkdir logs
            ${nginx}/sbin/nginx -p./ -t -c${nginxConfDir "logs"}/nginx.conf
          '';

        description = "nginx webserver";

        startOn = "started ${startingDependency} and filesystem";

        # TODO: does this also apply to nginx?

        # !!! This should be added in test-instrumentation.nix.  It
        # shouldn't hurt though, since packages usually aren't built
        # with coverage enabled.
        # GCOV_PREFIX = "/tmp/coverage-data";
       
        # PATH = concatStringsSep ":" (
        #   [ "${pkgs.coreutils}/bin" "${pkgs.gnugrep}/bin" ]
        #   ++ # Needed for PHP's mail() function.  !!! Probably the
        #      # ssmtp module should export the path to sendmail in
        #      # some way.
        #      optional config.networking.defaultMailServer.directDelivery "${pkgs.ssmtp}/sbin"
        #   ++ (concatMap (svc: svc.extraServerPath) allSubservices) );

        # PHPRC = if enablePHP then phpIni else "";

        # environment =
        #   {            # for PHP gettext, doesn't hurt much.
        #     LOCALE_ARCHIVE="${pkgs.glibcLocales}/lib/locale/locale-archive";

        #     TZ = config.time.timeZone;

        #   }; # // (listToAttrs (concatMap (svc: svc.globalEnvVars) allSubservices));
        preStart = ''
           mkdir -m 0700 -p ${cfg.logDir}
        '';

        # preStart =
        #  ''
        #    mkdir -m 0700 -p ${mainCfg.stateDir}
        #    mkdir -m 0700 -p ${mainCfg.logDir}

        #    ${optionalString (mainCfg.documentRoot != null)
        #    ''
        #      # Create the document root directory if does not exists yet
        #      mkdir -p ${mainCfg.documentRoot}
        #    ''
        #    }

        #    # Get rid of old semaphores.  These tend to accumulate across
        #    # server restarts, eventually preventing it from restarting
        #    # succesfully.
        #    for i in $(${pkgs.utillinux}/bin/ipcs -s | grep ' ${mainCfg.user} ' | cut -f2 -d ' '); do
        #        ${pkgs.utillinux}/bin/ipcrm -s $i
        #    done

        #    # Run the startup hooks for the subservices.
        #    for i in ${toString (map (svn: svn.startupScript) allSubservices)}; do
        #        echo Running Apache startup hook $i...
        #        $i
        #    done
        #  '';

        daemonType = "fork";

        exec = "${nginx}/sbin/nginx -c ${nginxConfDir cfg.logDir}/nginx.conf";

        #preStop =
        #  ''
        #    ${httpd}/bin/httpd -f ${httpdConf} -k graceful-stop
        #  '';
      };

  };

}
