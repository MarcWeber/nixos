[ ./config/fonts.nix
  ./config/gnu.nix
  ./config/i18n.nix
  ./config/krb5.nix
  ./config/ldap.nix
  ./config/networking.nix
  ./config/no-x-libs.nix
  ./config/nsswitch.nix
  ./config/power-management.nix
  ./config/pulseaudio.nix
  ./config/shells.nix
  ./config/swap.nix
  ./config/system-path.nix
  ./config/timezone.nix
  ./config/unix-odbc-drivers.nix
  ./config/users-groups.nix
  ./hardware/cpu/intel-microcode.nix
  ./hardware/network/b43.nix
  ./hardware/network/intel-2100bg.nix
  ./hardware/network/intel-2200bg.nix
  ./hardware/network/intel-3945abg.nix
  ./hardware/network/rt73.nix
  ./hardware/network/rtl8192c.nix
  ./hardware/pcmcia.nix
  ./hardware/all-firmware.nix
  ./installer/efi-boot-stub/efi-boot-stub.nix
  ./installer/generations-dir/generations-dir.nix
  ./installer/grub/grub.nix
  ./installer/grub/memtest.nix
  ./installer/init-script/init-script.nix
  ./installer/tools/nixos-checkout.nix
  ./installer/tools/tools.nix
  ./misc/assertions.nix
  ./misc/check-config.nix
  ./misc/crashdump.nix
  ./misc/ids.nix
  ./misc/locate.nix
  ./misc/lib.nix
  ./misc/nixpkgs.nix
  ./misc/passthru.nix
  ./misc/version.nix
  ./programs/bash/bash.nix
  ./programs/blcr.nix
  ./programs/info.nix
  ./programs/shadow.nix
  ./programs/ssh.nix
  ./programs/ssmtp.nix
  ./programs/wvdial.nix
  ./rename.nix
  ./security/ca.nix
  ./security/consolekit.nix
  ./security/pam.nix
  ./security/pam_usb.nix
  ./security/policykit.nix
  ./security/polkit.nix
  ./security/rtkit.nix
  ./security/setuid-wrappers.nix
  ./security/sudo.nix
  ./services/amqp/rabbitmq.nix
  ./services/audio/alsa.nix
  ./services/audio/fuppes.nix
  ./services/audio/pulseaudio.nix
  ./services/audio/mpd.nix
  ./services/backup/mysql-backup.nix
  ./services/backup/postgresql-backup.nix
  ./services/backup/sitecopy-backup.nix
  ./services/databases/4store-endpoint.nix
  ./services/databases/4store.nix
  ./services/databases/mongodb.nix
  ./services/databases/mysql.nix
  ./services/databases/mysql55.nix
  ./services/databases/openldap.nix
  ./services/databases/postgresql.nix
  ./services/databases/virtuoso.nix
  ./services/games/ghost-one.nix
  ./services/hardware/acpid.nix
  ./services/hardware/bluetooth.nix
  ./services/hardware/hal.nix
  ./services/hardware/nvidia-optimus.nix
  ./services/hardware/pcscd.nix
  ./services/hardware/pommed.nix
  ./services/hardware/sane.nix
  ./services/hardware/udev.nix
  ./services/hardware/udisks.nix
  ./services/hardware/upower.nix
  ./services/logging/klogd.nix
  ./services/logging/logrotate.nix
  ./services/logging/logstash.nix
  ./services/logging/syslogd.nix
  ./services/mail/dovecot.nix
  ./services/mail/dovecot2.nix
  ./services/mail/freepops.nix
  ./services/mail/mail.nix
  ./services/mail/postfix.nix
  ./services/misc/autofs.nix
  ./services/misc/disnix.nix
  ./services/misc/felix.nix
  ./services/misc/folding-at-home.nix
  ./services/misc/gpsd.nix
  ./services/misc/nix-daemon.nix
  ./services/misc/nix-gc.nix
  ./services/misc/nixos-manual.nix
  ./services/misc/rogue.nix
  ./services/misc/svnserve.nix
  ./services/misc/synergy.nix
  ./services/monitoring/monit.nix
  ./services/monitoring/nagios/default.nix
  ./services/monitoring/smartd.nix
  ./services/monitoring/systemhealth.nix
  ./services/monitoring/ups.nix
  ./services/monitoring/zabbix-agent.nix
  ./services/monitoring/zabbix-server.nix
  ./services/network-filesystems/drbd.nix
  ./services/network-filesystems/nfsd.nix
  ./services/network-filesystems/openafs-client/default.nix
  ./services/network-filesystems/samba.nix
  ./services/networking/amuled.nix
  ./services/networking/avahi-daemon.nix
  ./services/networking/bind.nix
  ./services/networking/bitlbee.nix
  ./services/networking/cntlm.nix
  ./services/networking/ddclient.nix
  #./services/networking/dhclient.nix
  ./services/networking/dhcpcd.nix
  ./services/networking/dhcpd.nix
  ./services/networking/dnsmasq.nix
  ./services/networking/ejabberd.nix
  ./services/networking/firewall.nix
  ./services/networking/flashpolicyd.nix
  ./services/networking/git-daemon.nix
  ./services/networking/gnunet.nix
  ./services/networking/gogoclient.nix
  ./services/networking/gvpe.nix
  ./services/networking/ifplugd.nix
  ./services/networking/ircd-hybrid/default.nix
  ./services/networking/nat.nix
  ./services/networking/nginx.nix
  ./services/networking/networkmanager.nix
  ./services/networking/ntpd.nix
  ./services/networking/oidentd.nix
  ./services/networking/openfire.nix
  ./services/networking/openvpn.nix
  ./services/networking/portmap.nix
  ./services/networking/prayer.nix
  ./services/networking/privoxy.nix
  ./services/networking/quassel.nix
  ./services/networking/radvd.nix
  ./services/networking/rdnssd.nix
  ./services/networking/rpcbind.nix
  ./services/networking/sabnzbd.nix
  ./services/networking/ssh/lshd.nix
  ./services/networking/ssh/sshd.nix
  ./services/networking/tftpd.nix
  ./services/networking/unbound.nix
  ./services/networking/vsftpd.nix
  ./services/networking/wakeonlan.nix
  ./services/networking/wicd.nix
  ./services/networking/wpa_supplicant.nix
  ./services/networking/xinetd.nix
  ./services/printing/cupsd.nix
  ./services/scheduling/atd.nix
  ./services/scheduling/cron.nix
  ./services/scheduling/fcron.nix
  ./services/security/frandom.nix
  ./services/security/tor.nix
  ./services/security/torsocks.nix
  ./services/system/cgroups.nix
  ./services/system/dbus.nix
  ./services/system/kerberos.nix
  ./services/system/nscd.nix
  ./services/system/uptimed.nix
  ./services/ttys/gpm.nix
  ./services/ttys/mingetty.nix
  ./services/web-servers/apache-httpd/default.nix
  ./services/web-servers/jboss/default.nix
  ./services/web-servers/tomcat.nix
  ./services/x11/desktop-managers/default.nix
  ./services/x11/display-managers/auto.nix
  ./services/x11/display-managers/default.nix
  ./services/x11/display-managers/kdm.nix
  ./services/x11/display-managers/slim.nix
  ./services/x11/hardware/multitouch.nix
  ./services/x11/hardware/synaptics.nix
  ./services/x11/hardware/wacom.nix
  ./services/x11/window-managers/awesome.nix
  ./services/x11/window-managers/compiz.nix
  ./services/x11/window-managers/default.nix
  ./services/x11/window-managers/icewm.nix
  ./services/x11/window-managers/kwm.nix
  ./services/x11/window-managers/metacity.nix
  ./services/x11/window-managers/none.nix
  ./services/x11/window-managers/twm.nix
  ./services/x11/window-managers/wmii.nix
  ./services/x11/window-managers/xmonad.nix
  ./services/x11/xfs.nix
  ./services/x11/xserver.nix
  ./system/activation/activation-script.nix
  ./system/activation/top-level.nix
  ./system/boot/kernel.nix
  ./system/boot/luksroot.nix
  ./system/boot/modprobe.nix
  ./system/boot/stage-1.nix
  ./system/boot/stage-2.nix
  ./system/etc/etc.nix
  ./system/upstart-events/control-alt-delete.nix
  ./system/upstart-events/runlevel.nix
  ./system/upstart-events/shutdown.nix
  ./system/upstart/upstart.nix
  ./tasks/cpu-freq.nix
  ./tasks/filesystems.nix
  ./tasks/filesystems/btrfs.nix
  ./tasks/filesystems/ext.nix
  ./tasks/filesystems/nfs.nix
  ./tasks/filesystems/reiserfs.nix
  ./tasks/filesystems/vfat.nix
  ./tasks/filesystems/xfs.nix
  ./tasks/kbd.nix
  ./tasks/lvm.nix
  ./tasks/network-interfaces.nix
  ./tasks/scsi-link-power-management.nix
  ./tasks/swraid.nix
  ./tasks/tty-backgrounds.nix
  ./virtualisation/libvirtd.nix
  ./virtualisation/nova.nix
  ./virtualisation/virtualbox-guest.nix
  ./virtualisation/xen-dom0.nix
]
