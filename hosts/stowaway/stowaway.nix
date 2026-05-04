{
  inputs,
  fleet,
  den,
  __findFile,
  ...
}:
{
  den.hosts.x86_64-linux = {
    stowaway = {
      description = "MacBookPro15,1 (T2) — covert field unit, dual-booted with macOS";
      users.cody = { };
    };
  };

  den.aspects = {
    # Per-user home-manager override for nomad: force Steam to launch with
    # `-cef-disable-gpu`. See comment on the host aspect below for rationale.
    nomad-steam-cef-fix = {
      description = "Steam desktop entry override — -cef-disable-gpu to avoid CEF SIGSEGV on T2 half-initialized iGPU";
      homeManager = _: {
        home.file.".local/share/applications/steam.desktop".text = ''
          [Desktop Entry]
          Name=Steam
          Comment=Application for managing and playing games on Steam
          Exec=steam -cef-disable-gpu %U
          Icon=steam
          Terminal=false
          Type=Application
          Categories=Network;FileTransfer;Game;
          MimeType=x-scheme-handler/steam;x-scheme-handler/steamlink;
          PrefersNonDefaultGPU=true
        '';
      };
    };

    stowaway = {
      # Forward the Steam CEF fix to every user on this host. Game rendering
      # still uses the GPU — only the Steam client UI runs in software.
      provides.to-users.includes = [ den.aspects.nomad-steam-cef-fix ];

      includes = [
        <fleet/unfree>
        <fleet/fonts>
        <fleet/phoenix>
        <fleet/mactahoe>
        <fleet/stylix>
        <fleet/kernel>
        <fleet/apps>
        <fleet/gaming>

        <fleet.system/ssh>
        <fleet.system/agent-user>
        <fleet.system/avahi>
        <fleet.system/virtualization>

        <fleet.hardware/apple-t2>
        (fleet.hardware {
          tailscale = true;
        })
        (fleet.desktop { default = "niri"; })

        <fleet.music/production>
        (fleet.selfhost._.samba-client { })

        (<fleet.disk/btrfs-partitions> {
          rootPartlabel = "stowaway-root";
          espPartlabel = "stowaway-esp";
          btrfsLabel = "stowaway";
          espLabel = "STOWAWAYESP";
        })

        (fleet.deploy { ip = "192.168.0.139"; })
      ];

      nixos =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        {
          imports = [
            inputs.nixos-hardware.nixosModules.apple-macbook-pro
          ];

          time.timeZone = "America/Los_Angeles";

          # 2019 MBP has Intel UHD 630 (iGPU) + AMD Radeon Pro 560X (dGPU).
          # Letting amdgpu own the display gives games full dGPU performance
          # (UHD 630 drags Super Battle Golf to 20fps; the 560X does 60+).
          # The Steam client's CEF crash is handled by `-cef-disable-gpu` in
          # the nomad-steam-cef-fix aspect, so we don't need to force iGPU.
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
  };
}
