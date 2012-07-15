# work in progress

/*

  Problem: ssd's have a short lifetime.
  Thus we should try hard to minimize writes.
  done:
  - syslog does not use sync (path are prefixed by -)

  what you can do: 
  
  * 
    mount tmpfs on /tmp (TODO do this automatically / is on ssd and /tmp is not mounted?)
    fileSystems = [
      { device = "tmpfs"; mountPoint="/tmp"; fsType = "tmpfs"; options = "size=1024m,mode=1777"; }
    ];

  * make browsers store the cache in tmpfs as well (evetnually sync to disk on shutdown?)

    == browsers ==
    firefox:
      browser.cache.disk.enable = false
      disk.cache.memory.capacity = 32768 (bytes)
      browser.cache.disk.parent_directory ..
    opera:
      opera:config#UserPrefs|CacheDirectory4 
    chrome:
      # disk-cache-size: bytes
      chrome --disk-cache-dir=/tmp/browser-cache-chrome --disk-cache-size=20000000 &;;


   * eventually journals of databases should be put on normal disk (TODO)

   * ssds should always be mounted noatime to reduce writes
    (TODO: force this ?)

   * ... this list is probably is incomplete

*/


# This module defines the global list of uids and gids.  We keep a
# central list to prevent id collissions.

{config, pkgs, ...}:

let

  inherit (pkgs) lib;
  # inherit (builtins) ;


  options = {

    # move this into a namespace along with fileSystems ?
    ssdDevices = lib.mkOption {
      description = ''list of devices being ssds.'';
      default = [];
      example = ["sda"];
      check = list: (lib.all (x: builtins.substring 0 4 x != "/dev") list);
    };

  };

in
  
{

  require = options;

  # even though 2.6 kernels should detect some ssd devices [1] changing IO scheduler
  # doesn't hurt:
  # [1]: http://git.kernel.org/gitweb.cgi?p=linux/kernel/git/torvalds/linux-2.6.git;a=commit;h=1308835ffffe6d61ad1f48c5c381c9cc47f683ec
  boot.postBootCommands =
    lib.concatMapStrings (x: "echo noop > /sys/block/${x}/queue/scheduler\n") config.ssdDevices;

}
