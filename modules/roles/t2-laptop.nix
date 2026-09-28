# T2 MacBook Pro field laptop (nomad, stowaway): dual-boots macOS, runs the
# niri desktop, gaming, and the music-production host half.
#
# Per-host facts stay on the host entry (deployment.ip, timeZone); the disk
# labels derive from the host name (<name>-root, <name>-esp, <NAME>ESP).
{
  inputs,
  lib,
  fleet,
  __findFile,
  ...
}:
{
  fleet.roles._.t2-laptop = {
    description = "MacBookPro15,1 (T2) field laptop — niri, gaming, music production, btrfs by partlabel";

    includes = [
      <fleet/fonts>
      <fleet/phoenix>
      <fleet/mactahoe>
      <fleet/stylix>
      <fleet/kernel>
      <fleet/gaming>

      <fleet.system/ssh>
      <fleet.system/agent-user>
      <fleet.system/avahi>
      <fleet.system/virtualization>

      <fleet.hardware/apple-t2>
      <fleet.hardware._.apple-t2/steam-cef-fix>
      (fleet.hardware {
        tailscale = true;
      })
      (fleet.desktop { default = "niri"; })

      <fleet.music/production>
      (fleet.selfhost._.samba-client { })

      (
        { host, ... }:
        <fleet.disk/btrfs-partitions> {
          rootPartlabel = "${host.name}-root";
          espPartlabel = "${host.name}-esp";
          btrfsLabel = host.name;
          espLabel = "${lib.toUpper host.name}ESP";
        }
      )
    ];

    nixos = {
      imports = [
        inputs.nixos-hardware.nixosModules.apple-macbook-pro
      ];

      # 2019 MBP has Intel UHD 630 (iGPU) + AMD Radeon Pro 560X (dGPU).
      # Letting amdgpu own the display gives games full dGPU performance
      # (UHD 630 drags Super Battle Golf to 20fps; the 560X does 60+).
      # The Steam client's CEF crash is handled by `-cef-disable-gpu`
      # (<fleet.hardware._.apple-t2/steam-cef-fix>), so we don't force iGPU.
      # hardware.apple-t2.enableIGPU = true;

      # Declaratively extract Broadcom Wi-Fi/BT firmware from Apple's
      # macOS recovery DMG at build time. Without this, BCM4364B3 stays
      # silent — only wired networking works.
      hardware.apple-t2.firmware.enable = true;
      hardware.apple-t2.firmware.version = "sonoma";

      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = false;
      boot.loader.efi.efiSysMountPoint = "/boot";

      networking.networkmanager.enable = true;
    };
  };
}
