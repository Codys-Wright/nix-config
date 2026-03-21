{
  inputs,
  den,
  pkgs,
  FTS,
  __findFile,
  ...
}:
{
  den.hosts.x86_64-linux = {
    THEBATTLESHIP = {
      description = "The Main System, ready for everyday battle";
      users.cody = { };
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
      # Include role-based aspects
      includes = [
        <FTS/fonts>
        <FTS/phoenix>

        # System-wide theme (bootloader, default appearance)

        # Linux-only user aspects (moved from cody user for cross-platform compat)
        <FTS.apps/gaming>
        <FTS.apps/flatpaks>
        <FTS.music/production>
        (<FTS.user/password> {
          method = "hashed";
          value = "$6$0C2OSNBUmq/740g7$VfDQJvfYnxCwlV/KlmAIz.z5jYpIVc7Qa.1pzL/Fu3UGprNVLSKljI310/gyeCiYOPhJ.TVijW62wTmY54Ols1";
        })
        <FTS.user/autologin>
        (FTS.selfhost._.samba-client { })
        FTS.mactahoe
        FTS.stylix

        # Complete desktop setup (environment + display manager + bootloader)
        <FTS.desktop/environment/hyprland>
        <FTS.desktop/environment/gnome>
        (<FTS.desktop/environment/kde> { })
        FTS.sddm
        (FTS.grub {
          uefi = true;
          # theme is set by system theme preset
        })

        # Disk and filesystem configuration
        (<FTS.system/disk> {
          type = "btrfs-impermanence";
          device = "/dev/nvme2n1";
          withSwap = true;
          swapSize = "205"; # 205GB swap for full hibernation
          persistFolder = "/persist";
        })

        # Hardware and kernel - manually include hardware sub-aspects except CUDA
        # (CUDA downloads fail due to SSL issues with NVIDIA servers)
        <FTS.kernel>
        <FTS.hardware._.facter>
        <FTS.hardware._.audio>
        <FTS.hardware._.bluetooth>
        # SKIP: <FTS.hardware._.cuda>  - Disabled due to download failures
        <FTS.hardware._.networking>
        <FTS.hardware._.networking._.tailscale>
        <FTS.hardware._.nvidia>
        <FTS.hardware._.storage>
        <FTS.keyboard>

        # mDNS/DNS-SD service discovery
        <FTS.system._.avahi>

        # Virtualization for Windows VMs (EASEUS backup recovery, etc.)
        <FTS.system._.virtualization>

        # Deployment configuration (SSH, networking, secrets, VM/ISO generation)
        (<FTS.deployment> { })

        # Standalone VPN for desktop use
        (FTS.selfhost._.protonvpn-standalone {
          usernameFile = "/run/secrets/cody/openvpn/username";
          passwordFile = "/run/secrets/cody/openvpn/password";
          killswitch = {
            enable = true;
            allowedSubnets = [
              "192.168.0.0/16"
              "10.0.0.0/8"
            ];
            exemptPorts = [ 22 ];
          };
        })

        # Self-hosting services are provided by the starcommand user
        # See users/starcommand/starcommand.nix for service configuration
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

          # Set KDE Plasma as the default session
          services.displayManager.defaultSession = lib.mkForce "plasma";

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
            device = "10.10.10.1:/mnt/storage";
            fsType = "nfs";
            options = [
              "nfsvers=4.2"
              "rsize=1048576"
              "wsize=1048576"
              "_netdev"
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

          # 10G network interface tuning - jumbo frames
          systemd.network.networks."20-10g" = {
            matchConfig.Name = "enp12s0 enp11s0";
            networkConfig.DHCP = "ipv4";
            linkConfig = {
              RequiredForOnline = false;
              MTUBytes = "9000";
            };
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
          users.users.cody.extraGroups = [ "libvirtd" ];
          users.users.cody.hashedPassword = "$6$0C2OSNBUmq/740g7$VfDQJvfYnxCwlV/KlmAIz.z5jYpIVc7Qa.1pzL/Fu3UGprNVLSKljI310/gyeCiYOPhJ.TVijW62wTmY54Ols1";

          # Import SOPS module
          imports = [
            inputs.sops-nix.nixosModules.default
          ];

          # SOPS configuration for secrets
          sops = {
            defaultSopsFile = ../../users/cody/secrets.yaml;
            age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
            secrets = {
              "cody/openvpn/username" = {
                owner = "root";
                group = "root";
                mode = "0400";
              };
              "cody/openvpn/password" = {
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
