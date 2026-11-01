# Lanzaboote behind shim: Secure Boot NixOS with the firmware's factory keys.
# The firmware trusts Ubuntu's Microsoft-signed shim (pkgs.shim-signed);
# shim trusts the sbctl db key from its MOK list and starts lanzaboote's
# signed systemd-boot, installed next to it as grubx64.efi. No key of ours
# lives in the firmware, so anti-cheat that wants factory keys (Valorant's
# Vanguard) is satisfied, and a BIOS update that resets the keys leaves NixOS
# booting.
#
#   <fleet.lanzaboote/shim>   (with <fleet/lanzaboote>)
#
# On every boot, and whenever lanzaboote rewrites systemd-boot, the shim files
# on the ESP are synced and the "NixOS (shim)" firmware entry is kept first
# in BootOrder. A pending one-time BootNext (e.g. into Windows) still wins once.
#
# One-time enrollment, needs someone at the screen:
#   openssl x509 -in /var/lib/sbctl/keys/db/db.pem -outform der -out db.der
#   mokutil --import db.der        # one-time password, confirmed in MokManager
# then reboot through shim, MokManager → Enroll MOK, and in the BIOS restore
# the factory keys. mokutil refuses a key that is already in the firmware db;
# hide db for that one call:
#   unshare -m sh -c 'mount --bind /dev/null /sys/firmware/efi/efivars/db-d719b2cb-3d3a-4596-a3bc-dad00e67656f && mokutil --import db.der'
{
  fleet.lanzaboote._.shim = {
    description = "Boot lanzaboote through Ubuntu's Microsoft-signed shim (sbctl key in MOK, factory firmware keys)";

    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        esp = config.boot.loader.efi.efiSysMountPoint;
        systemdBoot = "${esp}/EFI/systemd/systemd-bootx64.efi";

        sync = pkgs.writeShellApplication {
          name = "lanzaboote-shim-sync";
          runtimeInputs = with pkgs; [
            diffutils # cmp
            efibootmgr
            util-linux
            gnugrep
            gnused
            coreutils
          ];
          text = ''
            dir=${esp}/EFI/shim
            mkdir -p "$dir"

            # Copy only on change, through a temp file: a half-written loader
            # on the ESP is an unbootable machine.
            put() {
              if ! cmp -s "$1" "$2"; then
                cp "$1" "$2.new"
                sync
                mv "$2.new" "$2"
                echo "updated $2"
              fi
            }
            put ${pkgs.shim-signed}/share/shim/shimx64.efi "$dir/shimx64.efi"
            put ${pkgs.shim-signed}/share/shim/mmx64.efi "$dir/mmx64.efi"
            # shim starts the second stage by this exact name.
            put ${systemdBoot} "$dir/grubx64.efi"
            sync

            # The entry must point at this ESP: NVMe names change between boots,
            # so match on the partition's GPT UUID, never on /dev/nvmeN.
            part=$(findmnt -no SOURCE ${esp})
            partuuid=$(lsblk -no PARTUUID "$part")
            loader='\EFI\shim\shimx64.efi'
            find_entry() {
              efibootmgr -v | grep -iF "$partuuid" | grep -iF "$loader" \
                | sed -n 's/^Boot\([0-9A-Fa-f]\{4\}\).*/\1/p' | head -n1
            }
            entry=$(find_entry)
            if [ -z "$entry" ]; then
              disk=/dev/$(lsblk -no PKNAME "$part")
              partnum=$(cat "/sys/class/block/$(basename "$part")/partition")
              efibootmgr -q -c -d "$disk" -p "$partnum" -L "NixOS (shim)" -l "$loader"
              entry=$(find_entry)
            fi
            order=$(efibootmgr | sed -n 's/^BootOrder: //p')
            rest=$(echo "$order" | tr ',' '\n' | grep -vix "$entry" | paste -sd, -)
            new="$entry''${rest:+,$rest}"
            if [ "$order" != "$new" ]; then
              efibootmgr -q -o "$new"
              echo "BootOrder: $order -> $new"
            fi
          '';
        };

        unit = {
          unitConfig.RequiresMountsFor = esp;
          serviceConfig = {
            Type = "oneshot";
            ExecStart = lib.getExe sync;
          };
        };
      in
      {
        assertions = [
          {
            assertion = config.boot.lanzaboote.enable;
            message = "<fleet.lanzaboote/shim> needs <fleet/lanzaboote>";
          }
        ];

        environment.systemPackages = [ pkgs.mokutil ];

        # Boot and switch: RemainAfterExit, so a switch that changes the script
        # (a shim bump) re-runs it.
        systemd.services.lanzaboote-shim = lib.recursiveUpdate unit {
          description = "Sync shim to the ESP and keep it first in the UEFI boot order";
          wantedBy = [ "multi-user.target" ];
          serviceConfig.RemainAfterExit = true;
        };

        # lanzaboote rewrote systemd-boot: refresh grubx64.efi.
        systemd.services.lanzaboote-shim-refresh = lib.recursiveUpdate unit {
          description = "Refresh shim's second stage after lanzaboote updates systemd-boot";
        };
        systemd.paths.lanzaboote-shim-refresh = {
          wantedBy = [ "multi-user.target" ];
          pathConfig.PathChanged = systemdBoot;
        };
      };
  };
}
