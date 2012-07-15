# VirtualBox server additions
{ config, pkgs, ... }:

with pkgs.lib;

let
  modprobe = config.system.sbin.modprobe; 
  modules = "vboxnetflt vboxnetadp vboxdrv";
in
{

  options.services.virtualbox.host.enable = mkOption {
      default = false;
      description = "This only loads the kernel modules and adds VirtualBox to system PATH";
    };

  config = mkIf config.services.virtualbox.host.enable {
      environment.systemPackages = [ config.boot.kernelPackages.virtualbox ];
      boot.extraModulePackages = [ config.boot.kernelPackages.virtualbox ];

      # host (using upstart job so that this also works using nixos switch)
      jobs.virtualboxHost = {
          description = "this job loads virtualbox kernel modules";
          preStart = "for m in ${modules}; do ${modprobe}/sbin/modprobe $m; done";
          # preStop requires main
          postStop = "for m in ${modules}; do ${modprobe}/sbin/modprobe -r $m || true; done # this may fail if VMs are still running";
      };
  };
}
