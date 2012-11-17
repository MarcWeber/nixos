#!/bin/sh

# prepare installation by putting in place unless present:
# /etc/nixos/nixpkgs
# /etc/nixos/nixos
# /etc/nixos/configuration.nix


set -e

usage(){
  cat << EOF
  script options [list of actions]

  Example usage: nixos-prepare-install create-passwd copy-nix guess-config checkout-sources
  default list of actions: $DEFAULTS

  actions:
    [none]: /bin/sh symlink is always created if this script is run

    guess-config:     run nixos-hardware-scan > T/configuration.nix (TODO: implement this)
    copy-nix:         (1) copy minimal nix system which can bootstrap the whole
                      system unless bootstrapping from an archive in which case
                      file should be in place.
                      (2) registering store paths as valid
    copy-nixos-bootstrap:
                      copy the nixos-bootstrap script to /nix/store where it will be
                      garbage collected later
    copy-sources:     copy repos   into T/
    checkout-sources: git checkout official repos into T/ (TODO: official manifest should be used!)
    checkout-sources-git-marcweber: checkout nixos/nixpkgs patches maintained by Marc Weber T/

    create-passwd: some derivations (such as git checkout) requires a /etc/passwd file.
                   create a simple one.

    where T=$T
      and repos = $ALL_REPOS

  options:
    --force: If targets exist no action will taken unless you use --force
             in which case target is renamed before action is run
    --dir-ok: allow installing into directory (omits is mount point check)

    --debug: set -x


EOF
  exit 1
}


INFO(){ echo "INFO: " $@; }
CMD_ECHO(){ echo "running $@"; $@; }

# = configuration =

FORCE_ACTIONS=${FORCE_ACTIONS:-}
ALL_REPOS="nixpkgs nixos"
mountPoint=${mountPoint:-/mnt}

if [ -e $mountPoint/README-BOOTSTRAP-NIXOS ]; then
  INFO "$mountPoint/README-BOOTSTRAP-NIXOS found, assuming your're bootstrapping from an archive. Nix files should be in place"
  FROM_ARCHIVE=1
  DEFAULTS="guess-config copy-nix"
else
  FROM_ARCHIVE=0
  DEFAULTS="guess-config copy-nixos-bootstrap copy-nix copy-sources"
fi

backupTimestamp=$(date "+%Y%m%d%H%M%S")
SRC_BASE=${SRC_BASE:-"/etc/nixos"}
SVN_BASE="https://svn.nixos.org/repos/nix"
MUST_BE_MOUNTPOINT=${MUST_BE_MOUNTPOINT:-1}
T="$mountPoint/etc/nixos"

NIX_CLOSURE=${NIX_CLOSURE:-@nixClosure@}

# minimal bootstrap archive:
RUN_IN_CHROOT=$mountPoint/nix/store/run-in-chroot
# iso image case:
[ -f $RUN_IN_CHROOT ] || RUN_IN_CHROOT=run-in-chroot

die(){ echo "!>> " $@; exit 1; }

## = read options =
# actions is used by main loop at the end
ACTIONS=""
# check and handle options:
for a in $@; do
  case "$a" in
    copy-nix|copy-nixos-bootstrap|guess-config|copy-sources|checkout-sources|checkout-sources-git-marcweber|create-passwd)
      ACTIONS="$ACTIONS $a"
    ;;
    --dir-ok)
      MUST_BE_MOUNTPOINT=false
    ;;
    --force)
      FORCE_ACTIONS=1
    ;;
    --debug)
      set -x
    ;;
    *)
      echo "unkown option: $a"
      usage
    ;;
  esac
done
[ -n "$ACTIONS" ] || ACTIONS="$DEFAULTS"


if ! grep -F -q " $mountPoint " /proc/mounts && [ "$MUST_BE_MOUNTPOINT" = 1 ]; then
    die "$mountPoint doesn't appear to be a mount point"
fi

# = utils =

backup(){
  local dst="$(dirname "$1")/$(basename "$1")-$backupTimestamp"
  INFO "backing up: $1 -> $dst"
  mv "$1" "$dst"
}

# = implementation =

# exit status  = 0: target exists
# exti status != 0: target must be rebuild either because --force was given or
#                   because it didn't exist yet
target_realised(){
  if [ -e "$1" ] && [ "$FORCE_ACTIONS" = 1 ]; then
      backup "$1"
  fi

  [ -e "$1" ] && {
    INFO "not realsing $1. Target already exists. Use --force to force."
  }
}

createDirs(){
  mkdir -m 0755 -p $mountPoint/etc/nixos
  mkdir -m 1777 -p $mountPoint/nix/store

  # Create the required /bin/sh symlink; otherwise lots of things
  # (notably the system() function) won't work.
  mkdir -m 0755 -p $mountPoint/bin
  ln -sf @shell@ $mountPoint/bin/sh
  # TODO permissions of this file?
  mkdir -p -m 0755 $mountPoint/var/run/nix/current-load
  [ -e "$mountPoint/etc/nix.machines" ] || {
    CMD_ECHO touch "$mountPoint/etc/nix.machines"
  }

}


realise_repo(){
  local action=$1
  local repo=$2

  createDirs

  case "$action" in
    copy-sources)
      local repo_sources="${repo}_SOURCES"
      rsync -a -r "${SRC_BASE}/$repo" "$T"
    ;;
    checkout-sources)
      INFO "checking out $repo"
      local git_base=https://github.com/nixos
      CMD_ECHO git clone --depth=1 $url "$T/$repo"
    ;;
    checkout-sources-git-marcweber)
      INFO "checking out $repo"
      local git_base=https://github.com/MarcWeber
      local url=$git_base/$repo.git
      local branch
      case "$repo" in
        nixos)   branch=experimental/marc ;;
        nixpkgs) branch=experimental/marc ;;
      esac
      INFO "checkout out $repo"
      CMD_ECHO git clone --depth=1 -b $branch $url "$T/$repo"
    ;;
  esac

}

# only keep /nix/store/* lines
# print them only once
pathsFromGraph(){
  declare -A a
  local prefix=/nix/store/
  while read l; do
    if [ "${l/#$prefix/}" != "$l" ] && [ -z "${a["$l"]}" ]; then
      echo "$l";
      a["$l"]=1;
    fi
  done
}

createDirs

# = run actions: =
for a in $ACTIONS; do
  case "$a" in

    guess-config)
      createDirs
      target_realised "$config" || {
        INFO "creating simple configuration file"
        # does not work in chroot ? (readlink line 71 which is /sys/bus/pci/devices/0000:00:1a.0/driver/module -> ../../../../module/uhci_hcd here
        # $mountPoint/nix/store/run-in-chroot "@nixosHardwareScan@/bin/nixos-hardware-scan > /etc/nixos/configuration.nix"
        perl $mountPoint/@nixosHardwareScan@/bin/nixos-hardware-scan > $mountPoint/etc/nixos/configuration.nix
        echo
        INFO "Note: you can start customizing $config while remaining actions will are being executed"
        echo
      }
    ;;

    copy-nixos-bootstrap)
      createDirs
      # this script will be garbage collected somewhen:
      cp @nixosBootstrap@/bin/nixos-bootstrap $mountPoint/nix/store/
    ;;

    copy-nix)
      if [ "$FROM_ARCHIVE" = 1 ]; then
        NIX_CLOSURE=${mountPoint}@nixClosure@
      else
        INFO "Copy Nix to the Nix store on the target device."
        createDirs
        echo "copying Nix to $mountPoint...."

        for i in `cat $NIX_CLOSURE | pathsFromGraph`; do
            echo "  $i"
            rsync -a $i $mountPoint/nix/store/
        done

      fi

      [ -e "$NIX_CLOSURE" ] || die "Couldn't find nixClosure $NIX_CLOSURE anywhere. Can't register inital store paths valid. Exiting"

      INFO "registering bootstrapping store paths as valid so that they won't be rebuild"
      # Register the paths in the Nix closure as valid.  This is necessary
      # to prevent them from being deleted the first time we install
      # something.  (I.e., Nix will see that, e.g., the glibc path is not
      # valid, delete it to get it out of the way, but as a result nothing
      # will work anymore.)
      # TODO: check permissions so that paths can't be changed later?
      bash $RUN_IN_CHROOT '@nix@/bin/nix-store --register-validity' < $NIX_CLOSURE

    ;;

    create-passwd)
        if [ -x "$mountPoint/etc/passwd" ]; then
          echo "not overriding $mountPoint/etc/passwd"
        else
    cat > "$mountPoint/etc/passwd" << EOF
root:x:0:0:System administrator:/root:/var/run/current-system/sw/bin/zsh
nobody:x:65534:65534:Unprivileged account (don't use!):/var/empty:/noshell
nixbld1:x:30001:30000:Nix build user 1:/var/empty:/noshell
nixbld2:x:30002:30000:Nix build user 2:/var/empty:/noshell
nixbld3:x:30003:30000:Nix build user 3:/var/empty:/noshell
nixbld4:x:30004:30000:Nix build user 4:/var/empty:/noshell
nixbld5:x:30005:30000:Nix build user 5:/var/empty:/noshell
nixbld6:x:30006:30000:Nix build user 6:/var/empty:/noshell
nixbld7:x:30007:30000:Nix build user 7:/var/empty:/noshell
nixbld8:x:30008:30000:Nix build user 8:/var/empty:/noshell
nixbld9:x:30009:30000:Nix build user 9:/var/empty:/noshell
nixbld10:x:30010:30000:Nix build user 10:/var/empty:/noshell
EOF
        fi

    ;;

    copy-sources|checkout-sources|checkout-sources-git-marcweber)

      for repo in $ALL_REPOS; do
        target_realised "$T/$repo" || realise_repo $a $repo
      done

    ;;
  esac
done

if [ -e "$T/nixos" ] && [ -e "$T/nixpkgs" ] && [ -e "$T/configuration.nix" ]; then
  cat << EOF
    To realise your NixOS installtion execute:

    bash $RUN_IN_CHROOT "/nix/store/nixos-bootstrap --install -j2 --keep-going"
EOF
else
  for t in "$T/configuration.nix" "$T/nixpkgs" "$T/configuration.nix"; do
    INFO "you can't start because $t is missing"
  done
fi
