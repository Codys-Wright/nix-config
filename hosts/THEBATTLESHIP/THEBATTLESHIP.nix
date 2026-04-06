{
  inputs,
  FTS,
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
      includes = [
        <FTS/fonts>
        <FTS/phoenix>
        <FTS/mactahoe>
        <FTS/stylix>

        (FTS.desktop { default = "niri"; })
        (FTS.grub { uefi = true; })

        (FTS.hardware {
          nvidia = true;
          tailscale = true;
        })

        <FTS/gaming>
        <FTS/apps>

        (<FTS.system/disk> {
          type = "btrfs-impermanence";
          device = "/dev/nvme2n1";
          withSwap = true;
          swapSize = "205";
          persistFolder = "/persist";
        })

        <FTS/kernel>
        <FTS.music/production>
        (FTS.selfhost._.samba-client { })
        <FTS.system/avahi>
        <FTS.system/virtualization>
        (<FTS.deployment> { })

        # 10G network tuning for starcommand link
        (FTS.system._.network-10g { interface = "enp12s0"; })
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

          nix.gc = {
            automatic = true;
            dates = "weekly";
            options = "--delete-older-than 7d";
          };

          programs.nh.enable = true;

          # NTFS games partition
          fileSystems."run/media/GAMES" = {
            device = "/dev/nvme2n1p2";
            fsType = "ntfs-3g";
            options = [
              "rw"
              "uid=1000"
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
