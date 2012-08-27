/*

  YES: this file should be called "shell.nix" or the like.

  This module defines global configuration for different shells.
  Bash is the default shell.


  What should be supported?
  =========================

  When user logs in his/her account should be setup which means
    - setting up ~/.nix-{profile,defexpr}. See scriptSettingUpUserProfile below
    - setting up initial ~/.bashrc ~/.profile ~/.zsrhc .. files setting up
      completion etc. User can opt out by editing those files easily.
    - setting up env vars (NIX_DAEMON, PATH, ... etc) so that the sure can get
      his work done without bothering about Nix specific stuff and that scp etc
      find their remote executables!

  Because /etc/{bashrc,profile} are loaded before ~/{.bashrc,.profile,.bash_profile}
  you must not do anything user may dislike - because user can't opt-out!
  This includes setting up completion.

  Care must be taken that /etc/bashrc doesn't emit any additional lines which
  would break scp and the like

  strace reveals which files are sourced when:

   bash:
   =====
    is interactive? [ -n "$PS1" ]
    login shell (bash -l):
      /etc/profile 
      ~/.bash_profile
      ~/.bash_login
      ~/.profile
      ~/.inputrc
      /etc/inputrc

      ~/.bash_logout
      /etc/bash_logout

    interactive (bash):
      /etc/bashrc
      ~/.bashrc
      ~/.inputrc
      /etc/inputrc

    non interactive (#!/bin/sh):
      no /etc/* file
      no ~/* file

    ssh tools (scp) will ask bash/sh to run the remote process. A non login
    shell is being used.


   zsh:
   ====
    is interactive? [ -n "$PS1" ]
    login shell (zsh -l):
      /etc/zshenv
      ~/.zshenv
      /etc/zprofile
      /etc/zshrc
      ~/.zshrc

    interactive (zsh):
      /etc/zshenv
      ~/.zshenv
      /etc/zshrc
      ~/.zshrc

    non interactive (#!/usr/bin/env zsh):
      /etc/zshenv
      ~/.zshenv

*/
{ config, pkgs, ... }:

with pkgs.lib;

let

  inherit (pkgs) lib;


  options = {

    environment.supportedShells = mkOption {
      default = [ "bash" ];
      example = [ "bash" "zsh" ];
      description = "
        Which shells are fully supported by NixOS when set as login shell.
        See mergeShellCodeOption and nix-daemon.nix about how to write shell
        specific code.
      ";
    };

    environment.interactiveShellInitDefault = mkOption {
      default = true;
      description = ''
        unless set to false some defaults are used for both bash and zsh.
        eg nix-install and nix-query are defined
      '';
    };

    environment.interactiveShellInit = mkOption {
      default = [];
      description = ''
        Code which will be sourced in interactive shells.
        The /etc/skel/* files are setup to source an /etc file to which this code is written.
        Environment initialization should be done in shellInit.
        User can opt out easily by changing the shells initialization files (~/.zshrc ~/.bash_setup)
      '';
      type = types.shellCode config.environment.supportedShells;
    };

    environment.shellInit = mkOption {
      default = ['' ''];
      example = ''export PATH=/godi/bin/:$PATH'';
      description = "
        Script used to initialized user shell environments.
        Note: This code will always run whenever a bash shell is started.
        This includes login shells bash -l as well as remote shells started
        by scp.
        You should use it for initializing environment vars only.

        Have a a look at mergeShellCodeOption to learn how to write shell
        specific code.

        Add defaults for interactive shells to option interactiveShellInit
        ";
      type = types.shellCode config.environment.supportedShells;
    };

  };

  scriptSettingUpUserProfile = pkgs.substituteAll {
    isExecutable = true;
    src = ./script-setting-up-user-profile.sh;
    inherit (pkgs) coreutils;
  };

  profile = target: src: nix_setup_completion: shellInit:
    { # Script executed when the shell starts as a login shell.
      source = pkgs.substituteAll {
         inherit (pkgs) gnugrep;
         inherit src shellInit nix_setup_completion;
         inherit scriptSettingUpUserProfile;
          wrapperDir = config.security.wrapperDir;
          modulesTree = config.system.modulesTree;
      };
      inherit target;
    };

  etcFile = target: content: {
    source = if content == null then ../bash + "/${target}" else pkgs.writeText "file" content; # TODO saner name
    inherit target;
  };

in

{
  require = [options];

  environment.shellInit = ''

    # similar to PATH the first item is most important - user can override it
    export NIX_PROFILES="$HOME/.nix-profile /nix/var/nix/profiles/default /var/run/current-system/sw"

    # Initialise a bunch of environment variables. sort by name

    # Search directory for Aspell dictionaries.
    export ASPELL_CONF="dict-dir $HOME/.nix-profile/lib/aspell"

    export EDITOR=nano
    export LD_LIBRARY_PATH=/var/run/opengl-driver/lib:/var/run/opengl-driver-32/lib # !!! only set if needed
    export LOCALE_ARCHIVE=/var/run/current-system/sw/lib/locale/locale-archive
    export LOCATE_PATH=/var/cache/locatedb
    export MODULE_DIR=@modulesTree@/lib/modules
    export NIXPKGS_ALL=/etc/nixos/nixpkgs
    export NIXPKGS_CONFIG=/etc/nix/nixpkgs-config.nix
    export NIX_PATH=/nix/var/nix/profiles/per-user/root/channels/nixos:nixpkgs=/etc/nixos/nixpkgs:nixos=/etc/nixos/nixos:nixos-config=/etc/nixos/configuration.nix:services=/etc/nixos/services
    export NIX_USER_PROFILE_DIR="/nix/var/nix/profiles/per-user/$USER"
    export PAGER="less -R"


  '';

  environment.interactiveShellInit = lib.optionals config.environment.interactiveShellInitDefault [
      ''
          # these are two useful to miss
          nix-query-packages() {
            if [ -z "$1" ]; then
              echo "usage: nix-query name."
              echo "All packages and their attr paths containing the word ignoring case will be listed"
              echo "NIXPKGS_ALL must be set accordingly"
            else
              ( nix-env -qa \* --show-trace -P -f $NIXPKGS_ALL | grep -i "$1"; )
            fi
          }
          nix-install-package(){
            if [ -z "$1" ]; then
              echo "usage: nix-install attr-path"
              echo "Will run nix-env -iA .. for you"
              echo "NIXPKGS_ALL must be set accordingly"
            else
              nix-env -iA "$1" -f $NIXPKGS_ALL
            fi
          }
      ''
      {
        bash = ''
        # Provide a nice prompt.
        PROMPT_COLOR="1;31m"
        let $UID && PROMPT_COLOR="1;32m"
        PS1="\n\[\033[$PROMPT_COLOR\][\u@\h:\w]\\$\[\033[0m\] "
        if test "$TERM" = "xterm"; then
            PS1="\[\033]2;\h:\u:\w\007\]$PS1"
        fi

        # In interactive shells, check the window size after every command.
        # if [ -n "$PS1" ]; then
            shopt -s checkwinsize
        # fi

        # Some aliases.
        alias ls="ls --color=tty"
        alias ll="ls -l"
        alias l="ls -alh"
        alias which="type -P"

        # Read system-wide modifications.
        if test -f /etc/profile.local; then
            source /etc/profile.local
        fi

        # now done in bash-common.sh (TODO remove)
        # # try to find current terminal setting in system or user profile:
        # for p in {/var/run/current-system/sw,~/.nix-profile}/share/terminfo; do
        #   [ -e "$p/''${TERM:0:1}/$TERM" ] && {
        #     export TERMINFO="$p"
        #     # also required for bash?
        #     TERM=$TERM
        #   }
        # done
        # unset p
      '';
      zsh = ''
        # now done in zshrc.zsh (TODO remove)
        # # try to find current terminal setting in system or user profile:
        # # without this backspace etc may not work correctly
        # for p in {/var/run/current-system/sw,~/.nix-profile}/share/terminfo; do
        #   [ -e "$p/$TERM[1,1]/$TERM" ] && {
        #     export TERMINFO="$p"
        #     # looks like we have to reset TERM after telling zsh where to find TERMINFO ?
        #     TERM=$TERM
        #   }
        # done
        # unset p

        # setup completion:
        autoload -Uz compinit;
        PATH=$PATH:@gnugrep@/bin compinit

        # TODO this is incomplete!
      '';
      }];

  environment.etc =
    [ 
      ### BASH
      { # non login shells
        target = "bashrc";
        # don't setup user profile - be always silent - first connection could be scp
        source = pkgs.writeText "global-bashrc" ''
          source /etc/bash-common.sh
          '';
      }
      { # login shells
        target = "profile";
        source = pkgs.writeText "global-profile" ''
          source /etc/bash-common.sh
          ${scriptSettingUpUserProfile}
          '';
      }
      { # login and non login shells
        target = "bash-common.sh";
        source = pkgs.substituteAll {
          inherit (config.security) wrapperDir;
          src = ./bash-common.sh;
          shellInit = config.environment.shellInit.bash;
        };
      }
      ( # Configuration for readline in bash.
        etcFile "inputrc" null
      )
      ## BASH user skeleton files: .bashrc and .bash_profile source .bash_setup
       # (the file the user should customize) which defaults to sourcing the
       # system default bash setup
      ( etcFile "skel/.bashrc" ''
          source /etc/bash-user-system-default.sh
          # setup completion for interactive shells:
          if [ -n "$PS1" ]; then
            source /etc/bash-setup-completion.sh
          fi
        '')
      ( etcFile "skel/.bash_profile" "source ~/.bashrc")
      {
       target = "bash-user-system-default.sh";
       source = pkgs.substituteAll {
          src = ./bash-user-system-default.sh;
          interactiveShellInit = config.environment.interactiveShellInit.bash;
        };
      }
      ( etcFile "bash-setup-completion.sh" null)

    ]
      
    ### ZSH
    ++ ( lib.optionals (lib.elem "zsh" config.environment.supportedShells) [

      {
        # login and non login shells:
        target = "zshenv"; # this file is loaded always, /etc/zshrc seems to be loaded only for interactive zsh shells?
        source = pkgs.substituteAll {
          inherit (config.security) wrapperDir;
          src = ./zshrc.zsh;
          shellInit = config.environment.shellInit.zsh;
        };
      }

      ## BASH user skeleton files
      {
       target = "zsh-user-system-default.zsh";
       source = pkgs.substituteAll {
          src = ./zsh-user-system-default.zsh;
          interactiveShellInit = config.environment.interactiveShellInit.zsh;
       };
      }
      ( etcFile "skel/.zshrc" "source /etc/zsh-user-system-default.zsh")

      # initrc ?

    ] )

    ### Vim  (TODO: move to a sane place. Its that annoying that its worth fixing)
    ++ [
      ( etcFile "skel/.vimrc" "\" the existence of this file makes Vim switch into noncompatible mode which you want\n" )
    ]
    ### Nix  (TODO: move to a sane place)
    ++ [ {
      source = ./nixpkgs-config-sample.nix;
      target = "skel/.nixpkgs/config.nix";
    }
    ];

  system.build.binsh = pkgs.bashInteractive;

  system.activationScripts.binsh = stringAfter [ "stdio" ]
    ''
      # Create the required /bin/sh symlink; otherwise lots of things
      # (notably the system() function) won't work.
      mkdir -m 0755 -p /bin
      ln -sfn ${config.system.build.binsh}/bin/sh /bin/.sh.tmp
      mv /bin/.sh.tmp /bin/sh # atomically replace /bin/sh
    '';

}
