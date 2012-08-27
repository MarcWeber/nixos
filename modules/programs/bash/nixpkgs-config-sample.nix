# export CONFIG=no to disable this file
if (builtins.getEnv "CONFIG" == "no") then
{}
else
{ pkgs, ... } : {
  # uncomment to enable optional features

  # gnuplot.x11 = true;

  # subversion.perlBindings = true;

  # vim.ruby = true;

  # php.xdebug = true;

  # ruby.tags = true;

  # only i686 !
  # flashplayer.debug = true

  mercurial = {
    # atticSupport = true;
    # guiSupport = true;
    # pbranchSupport = true;
    # hgsubversionSupport = true;
    # mqSupport = true;
    # histeditSupport = true;
    # hgextconvertSupport = true;
    # collapseSupport = true;
    # record = true;
  };

  firefox = {
    # enableAdobeFlash = true;
    # enableMPlayer = false;
    # RealPlayer is disabled by default for legal reasons.
    # enableRealPlayer=false; 
    # enableGeckoMediaPlayer
    # jre = true;
  };

  /* add / override your own packages easily:
  packageOverrides = pkgs_not_overridden: {
    # myVim = vim.override { .. };

    # overlays
    ro = pkgs.overlay "ruby";
    ho = pkgs.overlay "haskell";

    git = pkgs_not_overridden.git.override {
      # useEmacs = false; 
      # svnSupport = true; 
      # guiSupport = true;
      # gitkGlobSupport = true;
      # perlBindings = true;
    }

    # see wiki about how to keep many packages up to date by creating a bundle like this:
    gimpCollection =
      let ps = p.deepOverride { gimp = pkgs.gimpGit; };
          plugins = ps.gimpPlugins;
      in misc.collection {
        name = "gimp-collection-${gimp.name}";
        list = [
            ps.gimp 
            plugins.fourier plugins.resynthesizer plugins.lqrPlugin plugins.gmic
            # plugins.elsamuko
        ];
      };


    # examples about wrapper scripts setting env vars to make eclipse and netbeans run:
    netbeansRunner = pkgs.stdenv.mkDerivation {
        name = "nix-netbeans-runner-script-${stdenv.system}";

        phases = "installPhase";
        installPhase = ''
          ensureDir $out/bin
          target=$out/bin/nix-run-netbeans-${stdenv.system}
          cat > $target << EOF
            #!/bin/sh
            export PATH=${pkgs.jre}/bin:\$PATH
            export LD_LIBRARY_PATH=${pkgs.gtkLibs216.glib}/lib:${pkgs.gtkLibs216.gtk}/lib:${pkgs.xlibs.libXtst}/lib:${pkgs.xlibs.libXt}/lib:${pkgs.xlibs.libXi}/lib
            # If you run out of XX space try these? -vmargs -Xms512m -Xmx1024m -showLocation -XX:MaxPermSize=256m
            netbeans="\$1"; shift
            exec \$netbeans "\$@"
          EOF
          chmod +x $target
          '';

        meta = { 
          description = "provide environment to run Eclipse";
          longDescription = ''
            Is there one distribution providing support for up to date Eclipse installations?
            There are various reasons why not.
            Installing binaries just works. Get Eclipse binaries form eclipse.org/downloads
            install this wrapper then run Eclipse like this:
            nix-run-eclipse $PATH_TO_ECLIPSE/eclipse/eclipse
            and be happy. Everything works including update sites.
            '';
          maintainers = [pkgs.lib.maintainers.marcweber];
          platforms = pkgs.lib.platforms.linux;
        };
    };
  
    eclipseRunner =
      pkgs.stdenv.mkDerivation {
      name = "nix-eclipse-runner-script-${stdenv.system}";

      phases = "installPhase";
      installPhase = ''
        ensureDir $out/bin
        target=$out/bin/nix-run-eclipse-${stdenv.system}
        cat > $target << EOF
        #!/bin/sh
        export PATH=${pkgs.jre}/bin:\$PATH
        export LD_LIBRARY_PATH=${pkgs.gtkLibs216.glib}/lib:${pkgs.gtkLibs216.gtk}/lib:${pkgs.xlibs.libXtst}/lib
        # If you run out of XX space try these? -vmargs -Xms512m -Xmx1024m -XX:MaxPermSize=256m
        netbeans="\$1"; shift
        exec \$netbeans -vmargs -Xms512m -Xmx2048m -XX:MaxPermSize=256m "\$@"
        EOF
        chmod +x $target
      '';

      meta = { 
        description = "provide environment to run Eclipse";
        longDescription = ''
          Is there one distribution providing support for up to date Eclipse installations?
          There are various reasons why not.
          Installing binaries just works. Get Eclipse binaries form eclipse.org/downloads
          install this wrapper then run Eclipse like this:
          nix-run-eclipse $PATH_TO_ECLIPSE/eclipse/eclipse
          and be happy. Everything works including update sites.
        '';
        maintainers = [pkgs.lib.maintainers.marcweber];
        platforms = pkgs.lib.platforms.linux;
      };
    };


  }
  */

}
