{
    # Snowfall Lib provides a customized `lib` instance with access to your flake's library
    # as well as the libraries available from your flake's inputs.
    lib,
    # An instance of `pkgs` with your overlays and packages applied is also available.
    pkgs,
    # You also have access to your flake's inputs.
    inputs,

    # Additional metadata is provided by Snowfall Lib.
    namespace, # The namespace used for your flake, defaulting to "internal" if not set.
    system, # The system architecture for this host (eg. `x86_64-linux`).
    target, # The Snowfall Lib target for this system (eg. `x86_64-iso`).
    format, # A normalized name for the system target (eg. `iso`).
    virtual, # A boolean to determine whether this system is a virtual target using nixos-generators.
    systems, # An attribute map of your defined hosts.

    # All other arguments come from the system system.
    config,
    ...
}:
with lib;
with lib.${namespace};
{
    imports = [
        inputs.disko.nixosModules.disko
        inputs.stylix.nixosModules.stylix
        inputs.home-manager.nixosModules.home-manager
        inputs.nixos-facter-modules.nixosModules.facter
    ];

    
    # Disk configuration
    FTS-FLEET.system.disk = {
      enable = true;
      type = "btrfs-impermanence";
      device = "/dev/nvme0n1";
    };

    # Bootloader configuration
    FTS-FLEET.system.boot.systemd-boot = enabled;



    # Configure the cody user with Home Manager
    snowfallorg.users.cody = {
        create = true;
        admin = true;
        home = {
            enable = true;
            path = "/home/cody";
        };
    };

    # System user configuration
    FTS-FLEET.config.user = {
        name = "cody";
        fullName = "Cody Wright";
        email = "cody@example.com";
        initialPassword = "password";
    };

    # Add cody user to selfhost group for storage access
    users.users.cody.extraGroups = [ "selfhost" ];

    # FTS-FLEET namespace configuration
    FTS-FLEET = {
        bundles.common = enabled;
        bundles.cli = enabled;
        desktop.type = "kde";  # Primary desktop environment
        desktop.environments = ["kde" "gnome"];  # Available desktop environments for theming

        
        
        system.themes.stylix = enabled;
        services.ssh = {
            enable = true;
            allowRootLogin = true;
            rootKeys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKXs4YKtweDc2OcDDE6LoENPqQc8W79QQczfK9XErG4z CodyWright@THEBATTLESHIP"
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAg2dGkiERNUOR9gA9BfUwvFARY+tlL/8dcZFeoMKJu7 cody@THEBATTLESHIP"
            ];
        };



        # Enable fonts with Apple Color Emoji
        system.fonts = {
            enable = true;
            enableAppleEmoji = true;
        };

        # Enable SOPS for secrets management
        programs.sops = enabled;
        
        # Programs
        programs.wireguard = enabled;

        # WireGuard VPN
        services.networking.wireguard-vpn = {
            enable = true;
            interface = "wg0";
            privateKeyFile = "/etc/wireguard/wg0.key";
            address = [ "10.2.0.2/32" ];
            dns = [ "10.2.0.1" ];
            peers = [{
                publicKey = "3UovAm+ES1DXOEjkBiCOEnOHaicDmaVHXmym6oPE7C8=";
                allowedIPs = [ "0.0.0.0/0" "::/0" ];
                endpoint = "146.70.195.82:51820";
                persistentKeepalive = 25;
            }];
            killswitch = {
                enable = true;
                allowedSubnets = [ "192.168.0.0/16" "10.0.0.0/8" ];
            };
            firewall = {
                enable = true;
                listenPort = 51820;
            };
        };
 # Remote Desktop Services
        services.remote-desktop = {
            moonlight.enable = true;
            sunshine.enable = true;
        };
# 🏠 Selfhost Configuration
        services.selfhost = {
            enable = true;
            baseDomain = "starcommand.live";
            systemIp = "192.168.1.46";
            # Enable ACME for local SSL certificates
            acme.email = "acodywright@gmail.com";
            # Cloudflare DNS credentials are now managed via SOPS
            
            # Enable network access for local devices
            networkAccess.enable = true;

            # Configure mDNS for local network discovery
            mdns = {
                enable = true;
                domain = "local";
                services = ["_http._tcp" "_https._tcp"];
            };

            
            # Storage configuration
            mounts = {
                fast = "/mnt/cache";     # Fast storage (SSD)
                slow = "/mnt/storage";   # Slow storage (HDD)
                config = "/persist/opt/services";  # Service configs
                merged = "/mnt/user";    # Merged storage view
            };
            
            # Enable service categories gradually to find working ones
            networking.enable = true;      # Tailscale, Syncthing, etc.
            networking.rustdesk-server = {
                enable = true;
            };
            
            # WireGuard VPN namespace for secure torrenting (disabled - using main VPN instead)
            networking.wireguard-netns = {
                enable = false;
            };
            dashboard.enable = true;       # Homepage dashboard
            media.enable = false;          # Jellyfin, Navidrome, etc. - temporarily disabled due to mergerfs permissions
            arr.enable = true;             # Sonarr, Radarr, Prowlarr, etc.
            productivity.enable = true;    # Vaultwarden, Miniflux, Paperless, etc.
            cloud.enable = false;           # Immich, Nextcloud, etc.
            utility.enable = true;         # Uptime Kuma, etc.
            downloads.enable = true;       # Deluge, etc.
            backup.enable = true;          # Backup services
            smarthome.enable = true;       # Home Assistant, etc.
            
            # Disable specific failing services
            networking.syncthing.enable = false;        # Missing /mnt/data/syncthing
            productivity.calibre.enable = false;        # Missing library directory
            productivity.radicale.enable = false;       # Missing htpasswd file
            
          
            networking.cloudflare-tunnel = {
              enable = true;
              tunnelId = "deb73ad4-6c56-4a61-b404-dd41cb56d2ae";
            };
            
           
        };

        hardware.storage.nas = {
            enable = true;
            mergerfs = {
                enable = true;
            };
        };

        services.samba = {
            enable = true;
            shares = {
                storage = {
                    path = "/mnt/storage";
                    comment = "NAS Storage Pool";
                    browseable = "yes";
                    writable = "yes";
                    "read only" = "no";
                    "guest ok" = "no";
                    "create mask" = "0644";
                    "directory mask" = "0755";
                    "valid users" = "cody";
                    "follow symlinks" = "yes";
                    "wide links" = "yes";
                };
            };
        };

    };


    # Additional system packages (GUI and specific tools)
    environment.systemPackages = with pkgs; [
        brave
        vscode
        snowfallorg.frost
        whitesur-wallpapers
        just
    ];

    # Enable built-in atlantic driver for TP-Link TX401 10Gb Ethernet
    boot.kernelModules = [ "atlantic" ];

    # 10Gb network configuration for direct connection to THEBATTLESHIP
    networking.interfaces.enp33s0 = {
        ipv4.addresses = [{
            address = "10.0.0.2";
            prefixLength = 24;
        }];
    };

    services.minecraft-server = {
        enable = true;
        eula = true;
        openFirewall = true;
    };
    # Add overlay to make custom packages available
    nixpkgs.overlays = [
        (final: prev: {
          whitesur-wallpapers = inputs.self.packages.${prev.system}.whitesur-wallpapers;
        })
      ];

    system.stateVersion = "24.05";
}
