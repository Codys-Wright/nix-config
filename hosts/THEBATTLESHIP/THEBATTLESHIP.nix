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
        (<FTS.user/password> { method = "hashed"; value = "$6$0C2OSNBUmq/740g7$VfDQJvfYnxCwlV/KlmAIz.z5jYpIVc7Qa.1pzL/Fu3UGprNVLSKljI310/gyeCiYOPhJ.TVijW62wTmY54Ols1"; })
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

          # Mount starcommand storage over 10G network via SSHFS
          fileSystems."/mnt/starcommand" = {
            device = "root@10.10.10.1:/mnt/storage";
            fsType = "fuse.sshfs";
            options = [
              "IdentityFile=/etc/ssh/ssh_host_ed25519_key"
              "StrictHostKeyChecking=accept-new"
              "UserKnownHostsFile=/etc/ssh/ssh_known_hosts"
              "allow_other"
              "default_permissions"
              "uid=1000"
              "gid=100"
              "reconnect"
              "ServerAliveInterval=15"
              "ServerAliveCountMax=3"
              "_netdev"
              "x-systemd.automount"
              "x-systemd.idle-timeout=60"
              "x-systemd.mount-timeout=30"
              "nofail"
            ];
          };

          # Add starcommand 10G host key to known hosts
          programs.ssh.knownHosts."10.10.10.1" = {
            publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIENFHgs8JqCE4/dO58AN8W4M2SRgetgar94m2ntI9xb8";
          };

          # SSHFS package
          environment.systemPackages = [ pkgs.sshfs ];

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
