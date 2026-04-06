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
      # users.starcommand = {}; # Service user for self-hosting infrastructure
      aspect = "THEBATTLESHIP";

      # Use standard nixos-rebuild without patches
      # (starcommand user with lldap and other patched services is disabled)
      # Don't apply selfhostblocks patches since THEBATTLESHIP doesn't use lldap
    };
  };

  # THEBATTLESHIP host-specific aspect that includes role-based aspects
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
          # cuda = true;  # Disabled: download failures due to NVIDIA SSL issues
        })

        <FTS/gaming>

        <FTS/apps>

        (<FTS.system/disk> {
          type = "btrfs-impermanence";
          device = "/dev/nvme2n1";
          withSwap = true;
          swapSize = "205"; # 205GB swap for full hibernation
          persistFolder = "/persist";
        })

        <FTS/kernel>
        <FTS.music/production>
        (FTS.selfhost._.samba-client { })
        <FTS.system/avahi>
        <FTS.system/virtualization>
        (<FTS.deployment> { })
      ];

      # Manually set fileSystems and bootloader for now
      nixos =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        {
          # Hardware detection is handled by FTS.hardware (includes FTS.hardware.facter)
          # The facter report path is auto-derived as hosts/THEBATTLESHIP/facter.json

          # Timezone
          time.timeZone = "America/Los_Angeles";

          # Note: Overlays for stable/unstable package access are already configured
          # globally in modules/nix/nix.nix. The base nixpkgs is already unstable.
          # You can access stable packages via pkgs.stable and unstable via pkgs.unstable.

          # Limit number of generations in boot partition
          boot.loader.grub.configurationLimit = 15;

          # Automatic cleanup
          nix.gc = {
            automatic = true;
            dates = "weekly";
            options = "--delete-older-than 7d";
          };

          programs.nh.enable = true;

          fileSystems."run/media/GAMES" = {
            device = "/dev/nvme2n1p2";
            fsType = "ntfs-3g";
            options = [
              "rw"
              "uid=1000"
            ];
          };

          # Mount starcommand storage over 10G network via NFS
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

          # Keep starcommand 10G host key for SSH access
          programs.ssh.knownHosts."10.10.10.1" = {
            publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIENFHgs8JqCE4/dO58AN8W4M2SRgetgar94m2ntI9xb8";
          };

          # 10G network interface tuning - jumbo frames via NetworkManager
          networking.networkmanager.ensureProfiles.profiles."10g-jumbo" = {
            connection = {
              id = "10G Jumbo";
              type = "ethernet";
              interface-name = "enp12s0";
              autoconnect = "true";
            };
            ethernet.mtu = 9000;
            ipv4.method = "auto";
            ipv6.method = "auto";
          };

          # TCP buffer tuning for 10G throughput
          boot.kernel.sysctl = {
            "net.core.rmem_max" = 16777216;
            "net.core.wmem_max" = 16777216;
            "net.core.rmem_default" = 1048576;
            "net.core.wmem_default" = 1048576;
            "net.ipv4.tcp_rmem" = "4096 1048576 16777216";
            "net.ipv4.tcp_wmem" = "4096 1048576 16777216";
            "net.core.netdev_max_backlog" = 5000;
          };

          # NFS client support
          environment.systemPackages = [ pkgs.nfs-utils ];

          # Add cody to libvirtd group for VM management
          users.users.cody.extraGroups = [
            "adbusers"
            "audio"
            "docker"
            "input"
            "kvm"
            "libvirtd"
          ];

          # Import SOPS module
          imports = [
            inputs.sops-nix.nixosModules.default
          ];

          # SOPS configuration for secrets
          sops = {
            defaultSopsFile = ../../users/cody/secrets.yaml;
            age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
            secrets = {
              "cody/proton/privatekey" = {
                owner = "root";
                group = "root";
                mode = "0400";
              };
            };
          };

          # Self-hosting services configuration is handled by the starcommand user
          # See users/starcommand/starcommand.nix for all service configuration
        };
    };
  };
}
