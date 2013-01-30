# VirtualBox server additions
{ config, pkgs, ... }:

with pkgs.lib;

let
  modprobe = config.system.sbin.modprobe; 
  modules = "vboxnetflt vboxnetadp vboxdrv";

  script = pkgs.writeScript "virtualbox-server" ''
  #!/bin/sh
  if [ "$1" == start ]; then
    for m in ${modules}; do ${modprobe}/sbin/modprobe $m; done;
  else
    for m in ${modules}; do ${modprobe}/sbin/modprobe $m; done;
  fi
  '';
in
{
  options.services.virtualbox.host.enable = mkOption {
    default = false;
    description = "This only loads the kernel modules and adds VirtualBox to system PATH";
  };

  config = mkIf config.services.virtualbox.host.enable {
      environment.systemPackages = [ config.boot.kernelPackages.virtualbox ];
      boot.extraModulePackages = [ config.boot.kernelPackages.virtualbox ];

      systemd.units."virtualbox-server.service".text = ''
          [Unit]
          Description=load virtual box kernel modules

          [Service]
          ExecStart=${script} start
          ExecStop=${script} stop
          Type=oneshot
        '';

  };
}
