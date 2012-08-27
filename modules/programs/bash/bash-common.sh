# ! keep in sync with other shell implementations !

# sourced by /etc/bashrc and /etc/profile so set PATH and Nix specific vars are
# setup only for login shells or non login shells not inheriting env var (eg
# scp remote process)

# See comments in modules/programs/bash/bash.nix file

if [ -z "$NIX_DID_SHELL_INIT" ]; then
  # initial setup

  # export so that subshells don't rerun this code
  export NIX_DID_SHELL_INIT=1
  @shellInit@

fi

if [ "$(type -p nix_export_a 2>/dev/null)" != "function" ]; then
  # define some helper functions if not defined yet:

  # helper function prefixing - appending a item to an env var
  # eg: nix_export_a PATH NEW --prefix|--suffix
  nix_export_a(){
    local sep="$1"
    local var="$2"
    local value="$3"
    local mode="${4:---prefix}" # set to any value to add last
    if [ "$mode" == "--prefix" ]; then
      export "$var=${value}${!var:+$sep}${!var}"
    else
      export "$var=${!var}${!var:+$sep}${value}"
    fi
  }

  # add env vars for different profiles. Define a function so that user can reuse this code
  # I'm not sure wether this global file should know about ALSA, GStreamer, ..
  # specific stuff - but everything else would be much more complicated?
  nix_add_profile_vars(){
      local i="$1"
      local mode=${2:---prefix}

      # We have to care not leaving an empty PATH element, because that means '.' to Linux
      nix_export_a : PATH "$i/bin:$i/sbin:$i/lib/kde4/libexec" $mode
      nix_export_a : INFOPATH "$i/info:$i/share/info" $mode
      nix_export_a : PKG_CONFIG_PATH "$i/lib/pkgconfig" $mode

      # "lib/site_perl" is for backwards compatibility with packages
      # from Nixpkgs <= 0.12.
      nix_export_a : PERL5LIB "$i/lib/perl5/site_perl:$i/lib/site_perl" $mode

      # ALSA plugins
      nix_export_a : ALSA_PLUGIN_DIRS "$i/lib/alsa-lib" $mode

      # GStreamer.
      nix_export_a : GST_PLUGIN_PATH "$i/lib/gstreamer-0.10" $mode

      # KDE/Gnome stuff.
      nix_export_a : KDEDIRS "$i"
      nix_export_a : STRIGI_PLUGIN_PATH "$i/lib/strigi/" $mode
      nix_export_a : QT_PLUGIN_PATH "$i/lib/qt4/plugins:$i/lib/kde4/plugins" $mode
      nix_export_a : QTWEBKIT_PLUGIN_PATH "$i/lib/mozilla/plugins/" $mode
      nix_export_a : XDG_CONFIG_DIRS "$i/etc/xdg" $mode
      nix_export_a : XDG_DATA_DIRS "$i/share" $mode

      # mozilla plugins
      nix_export_a : MOZ_PLUGIN_PATH $i/lib/mozilla/plugins $mode

      # requires resetting TERM env var to take effect
      if [ -d $i/share/terminfo ]; then
        nix_export_a : TERMINFO_DIRS $i/share/terminfo
        TERM=$TERM
      fi

      # not sure how well this scales - this mayb e refactored in the future
      # alternative would be introduciing /etc/xml/catalog which might be more impure
      for kind in dtd xsl; do
        if test -d $i/xml/$kind; then
          for j in $(find $i/xml/$kind -name catalog.xml); do
            nix_export_a ' ' XML_CATALOG_FILES "$j" $mode
          done
        fi
      done
  }

fi

if [ -z "$NIX_VAR_SETUP" ]; then

  # export so that its skipped if you run (non login) shells (eg bash) again
  export NIX_VAR_SETUP=1

  for p in $NIX_PROFILES; do
    # start with most important profile so that those completion scripts get
    # sourced, thus suffix paths
    nix_add_profile_vars "$p" --suffix
  done

  # The setuid wrappers override other bin directories.
  export PATH=@wrapperDir@:$PATH

  # ~/bin if it exists overrides other bin directories.
  if test -d $HOME/bin; then
      export PATH=$HOME/bin:$PATH
  fi

fi
