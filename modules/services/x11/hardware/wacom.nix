{ config, pkgs, ... }:

with pkgs.lib;

let

  cfg = config.services.xserver.wacom;

in

{

  options = {

    services.xserver.wacom = {

      enable = mkOption {
        default = false;
        description = "Whether to enable the Wacom touchscreen/digitizer/tablet.";
      };

    };

  };


  config = mkIf cfg.enable {

    environment.systemPackages = [ pkgs.xf86_input_wacom ]; # provides xsetwacom

    services.xserver.modules = [ pkgs.xf86_input_wacom ];

    services.udev.packages = [ pkgs.xf86_input_wacom ];

    environment.etc."X11/xorg.conf.d/50-wacom.conf".source = "${pkgs.xf86_input_wacom}/share/X11/xorg.conf.d/50-wacom.conf";

  };

}
