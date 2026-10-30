# electric runs unattended: carter logs in by himself and the session never
# locks or blanks, and the desktop can be seen and driven over SSH: cua-driver
# (<fleet.system/cua-desktop>), or as root whatever the compositor:
#   screenshot: ffmpeg -f kmsgrab -i - -vf hwdownload,format=bgr0 -frames:v 1 shot.png
#   input:      ydotool click / type / mousemove (ydotoold runs as a service)
# Interactive remote desktop is Sunshine (from <fleet/gaming>) + Moonlight.
{ __findFile, ... }:
{
  den.aspects.electric-remote = {
    description = "Unattended electric: carter autologin, no screen lock, KMS screenshots + ydotool over SSH";

    nixos =
      { pkgs, ... }:
      {
        programs.ydotool.enable = true;
        environment.systemPackages = [ pkgs.ffmpeg ];

        # A reboot must come back to NixOS, not Windows: keep the firmware entry
        # for (lanzaboote's signed) systemd-boot first in BootOrder, creating it
        # if missing. Runs on every boot and switch, so a Windows update that
        # moves its boot manager to the front is undone the next time NixOS runs.
        systemd.services.nixos-first-boot-entry = {
          description = "Keep systemd-boot first in the UEFI boot order";
          wantedBy = [ "multi-user.target" ];
          after = [ "boot.mount" ];
          path = with pkgs; [
            efibootmgr
            util-linux
            gnugrep
            gnused
            coreutils
          ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script = ''
            loader='\EFI\systemd\systemd-bootx64.efi'
            entry=$(efibootmgr -v | grep -i 'systemd-bootx64.efi' | sed -n 's/^Boot\([0-9A-Fa-f]\{4\}\).*/\1/p' | head -n1)
            if [ -z "$entry" ]; then
              part=$(findmnt -no SOURCE /boot)
              disk=/dev/$(lsblk -no PKNAME "$part")
              partnum=$(cat /sys/class/block/$(basename "$part")/partition)
              efibootmgr -q -c -d "$disk" -p "$partnum" -L "Linux Boot Manager" -l "$loader"
              entry=$(efibootmgr -v | grep -i 'systemd-bootx64.efi' | sed -n 's/^Boot\([0-9A-Fa-f]\{4\}\).*/\1/p' | head -n1)
            fi
            order=$(efibootmgr | sed -n 's/^BootOrder: //p')
            rest=$(echo "$order" | tr ',' '\n' | grep -vix "$entry" | paste -sd, -)
            new="$entry''${rest:+,$rest}"
            if [ "$order" != "$new" ]; then
              efibootmgr -q -o "$new"
              echo "BootOrder: $order -> $new"
            fi
            # A pending one-time BootNext (e.g. into Windows) still wins once.
          '';
        };
      };
  };

  den.aspects.carter-electric-unattended = {
    description = "carter on electric: autologin, Loft never locks or turns the screen off";

    includes = [ <fleet.user/autologin> ];

    homeManager.programs.loft.idle = {
      lockAfter = null;
      screenOffAfter = null;
    };
  };
}
