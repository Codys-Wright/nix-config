# electric — Carter's desktop (Gigabyte B650 GAMING X AX V2), NixOS on the
# Inland QN450 NVMe, dual-booting Windows ("battleship" on Tailscale) from
# the Samsung SSD. Secure Boot stays on: lanzaboote signs with the sbctl db
# key, which is appended to the firmware's factory db (BIOS updates reset db:
# re-append it from Boot > Secure Boot > Expert Key Management).
# Ported from github:electricsss/electric-flake.
{ den, __findFile, ... }:
{
  den.hosts.x86_64-linux.electric = {
    description = "Carter's desktop system";
    timeZone = "America/Los_Angeles";
    deployment.ip = "100.65.190.11";
    settings.desktop.session = "niri";
    users.carter = { };
  };

  den.aspects.electric = {
    includes = [
      <fleet/unfree>
      <fleet/desktop>
      <fleet/lanzaboote>

      <fleet/hardware>
      <fleet.networking/tailscale>
      <fleet.networking/rustdesk> # remote desktop over Tailscale (Sunshine is the unattended route)

      <fleet/stylix>
      <fleet/mactahoe> # MacTahoe-blue icons (Loft's icon theme), GTK theme, cursors, Nautilus
      <fleet/fonts>
      <fleet/kernel>
      <fleet.system/avahi>
      <fleet.system/printing>
      <fleet/gaming>
      # Host half of music production; carter's half is in carter-electric.
      <fleet.music/production>

      den.aspects.electric-remote
      (<fleet.system/cua-desktop> { user = "carter"; })

      (<fleet.disk/btrfs> { device = "/dev/nvme0n1"; })
    ];

    nixos = {
      # UEFI shell entry, used to find the Windows device handle below
      # (`map -c`, then HDxxx:\EFI\Microsoft\Boot\Bootmgfw.efi).
      boot.loader.systemd-boot.edk2-uefi-shell.enable = true;

      # Windows dual-boot entry (Samsung SSD EFI partition)
      boot.loader.systemd-boot.windows."Windows" = {
        title = "Windows";
        efiDeviceHandle = "HD0b65535a2";
        sortKey = "z_windows";
      };

      # Don't wait 2 minutes for user sessions to stop on shutdown
      systemd.settings.Manager.DefaultTimeoutStopSec = "15s";

      # Classic dbus, as on 26.05: nixpkgs now defaults to dbus-broker, and
      # switching implementations is blocked on a live switch (needs a reboot).
      # electric is deployed without rebooting.
      services.dbus.implementation = "dbus";

      boot.supportedFilesystems = [ "ntfs-3g" ];

      # Windows drives, mounted on first access
      fileSystems =
        let
          ntfs = device: {
            inherit device;
            fsType = "ntfs-3g";
            options = [
              "rw"
              "uid=1000"
              "gid=100"
              "nofail"
              "noauto"
              "x-systemd.automount"
              "x-systemd.idle-timeout=0"
            ];
          };
        in
        {
          "/run/media/carter/storage" = ntfs "/dev/disk/by-uuid/DC92EE3E92EE1CB0";
          "/run/media/carter/windows" = ntfs "/dev/disk/by-uuid/E0F87CCFF87CA606";
          "/run/media/carter/games" = ntfs "/dev/disk/by-uuid/5ECE9AC5CE9A94BD";
        };

      # Passwords come from the config only (no passwd overrides)
      users.mutableUsers = false;
    };
  };
}
