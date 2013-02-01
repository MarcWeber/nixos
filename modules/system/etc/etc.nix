# Produce a script to generate /etc.
{ config, pkgs, ... }:

with pkgs.lib;

###### interface
let

  cfg = config.environment;

  option = {

    environment.etc = mkOption {
      default = [];
      example = [
        { source = "/nix/store/.../etc/dir/file.conf.example";
          target = "dir/file.conf";
          mode = "0440";
        }
      ];
      description = ''
        List of files that have to be linked in <filename>/etc</filename>.
      '';
      type = types.listOf types.optionSet;
      options = {
        source = mkOption {
          description = "Source file.";
        };
        target = mkOption {
          description = "Name of symlink (relative to <filename>/etc</filename>).";
        };
        mode = mkOption {
          default = "symlink";
          example = "0600";
          description = ''
            If set to something else than <literal>symlink</literal>,
            the file is copied instead of symlinked, with the given
            file mode.
          '';
        };
      };
    };

    environment.etcFilesProvidedByAdmin = mkOption {
      exmaple = ["nix.machines"];
      default = [];
      description = ''
        While being pure is nice sometimes its more convenient to provide /etc files yourself.
        Nice use cases could be /etc/hosts and /etc/nix.machines for instance.
        A quick alternative is mv /etc/hosts{,.backup} get your job done and move it back.
      '';
    };

  };
in

###### implementation
let

  etc = pkgs.stdenv.mkDerivation {
    name = "etc";

    builder = ./make-etc.sh;

    preferLocalBuild = true;

    /* !!! Use toXML. */
    sources = map (x: x.source) cfg.etc;
    targets = map (x: if (elem x cfg.etcFilesProvidedByAdmin)
                      then "${x.target}.sample" else x.target)
                  cfg.etc;
    modes = map (x: x.mode) cfg.etc;
  };

in

{
  require = [option];

  system.build.etc = etc;

  system.activationScripts.etc = stringAfter [ "stdio" ]
    ''
      # Set up the statically computed bits of /etc.
      echo "setting up /etc..."
      ${pkgs.perl}/bin/perl ${./setup-etc.pl} ${etc}/etc
    '';

}
