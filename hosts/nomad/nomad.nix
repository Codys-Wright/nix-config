{
  inputs,
  fleet,
  __findFile,
  ...
}:
{
  den.hosts.x86_64-linux = {
    nomad = {
      description = "MacBookPro15,1 (T2) — covert field unit, dual-booted with macOS";
      users.cody = { };
      aspect = "nomad";
    };
  };

  den.aspects = {
    nomad = {
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
          rootPartlabel = "nomad-root";
          espPartlabel = "nomad-esp";
          btrfsLabel = "nomad";
          espLabel = "NOMADESP";
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

          boot.loader.systemd-boot.enable = true;
          boot.loader.efi.canTouchEfiVariables = false;
          boot.loader.efi.efiSysMountPoint = "/boot";

          networking.networkmanager.enable = true;
        };
    };
  };
}
