{
  inputs,
  fleet,
  __findFile,
  ...
}:
{
  den.hosts.x86_64-linux = {
    THEBATTLESHIP = {
      description = "The Main System, ready for everyday battle";
      users.cody = { };
      users.joshua = { };
      users.guest = { };
      aspect = "THEBATTLESHIP";
    };
  };

  den.aspects = {
    THEBATTLESHIP = {
      provides.to-users.includes = [ <fleet.desktop/home> ];

      includes = [
        <fleet/unfree>
        <fleet/fonts>
        <fleet/phoenix>
        <fleet/mactahoe>
        <fleet/stylix>
        <fleet.system/agent-user>

        (fleet.desktop { default = "niri"; })
        (fleet.grub { uefi = true; })

        (fleet.hardware {
          nvidia = true;
          tailscale = true;
        })

        <fleet/gaming>
        <fleet/apps>

        (<fleet.system/disk> {
          type = "btrfs-impermanence";
          device = "/dev/nvme2n1";
          withSwap = true;
          swapSize = "205";
          persistFolder = "/persist";
        })

        <fleet/kernel>
        <fleet.music/production>
        (fleet.selfhost._.samba-client { })
        <fleet.system/avahi>
        <fleet.system/virtualization>
        (fleet.deploy { ip = "100.74.250.99"; })

        # 10G network tuning for starcommand link
        (fleet.system._.network-10g { interface = "enp12s0"; })
      ];

      nixos =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        {
          time.timeZone = "America/Los_Angeles";
          boot.loader.grub.configurationLimit = 15;

          # Prevent Intel i225 (igc/enp11s0) PCIe link loss after extended uptime.
          # The igc driver has a known issue where PCIe ASPM L1 substates cause
          # "PCIe link lost, device now detached" after hours of uptime.
          boot.kernelParams = [ "pcie_aspm=off" ];

          nix.gc = {
            automatic = true;
            dates = "weekly";
            options = "--delete-older-than 7d";
          };

          programs.nh.enable = true;

          # NTFS games partition
          fileSystems."/run/media/GAMES" = {
            device = "/dev/nvme2n1p2";
            fsType = "ntfs-3g";
            options = [
              "rw"
              "uid=1000"
            ];
          };

          # NTFS audio production partition
          fileSystems."/run/media/AudioHaven" = {
            device = "/dev/nvme1n1p2";
            fsType = "ntfs-3g";
            options = [
              "rw"
              "uid=1000"
              "nofail"
            ];
          };

          # Mount starcommand storage over 10G NFS
          fileSystems."/mnt/starcommand" = {
            device = "10.10.10.1:/";
            fsType = "nfs";
            options = [
              "nfsvers=4.2"
              "rsize=1048576"
              "wsize=1048576"
              "_netdev"
              "noauto"
              "x-systemd.automount"
              "x-systemd.idle-timeout=600"
              "x-systemd.mount-timeout=30"
              "nofail"
              "soft"
              "timeo=150"
              "retrans=3"
            ];
          };

          programs.ssh.knownHosts."10.10.10.1" = {
            publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIENFHgs8JqCE4/dO58AN8W4M2SRgetgar94m2ntI9xb8";
          };

          # SOPS secrets
          imports = [ inputs.sops-nix.nixosModules.default ];
          sops = {
            defaultSopsFile = ../../users/cody/secrets.yaml;
            age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
            secrets."cody/proton/privatekey" = {
              owner = "root";
              group = "root";
              mode = "0400";
            };
          };
        };
    };
  };
}
