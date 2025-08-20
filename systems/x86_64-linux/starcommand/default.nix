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

    # FTS-FLEET namespace configuration
    FTS-FLEET = {
        bundles.common = enabled;
        bundles.cli = enabled;
        desktop.type = "gnome";  # Primary desktop environment
        desktop.environments = ["kde" "gnome"];  # Available desktop environments for theming

        
        
        # system.themes.stylix = enabled;
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
# 🏠 Selfhost Configuration
        services.selfhost = {
            enable = true;
            baseDomain = "starcommand.live";
            # Enable ACME for local SSL certificates
            acme.email = "acodywright@gmail.com";
            # Cloudflare DNS credentials are now managed via SOPS
            
            # Enable network access for local devices
            networkAccess.enable = true;
            
            # Storage configuration
            mounts = {
                fast = "/mnt/cache";     # Fast storage (SSD)
                slow = "/mnt/storage";   # Slow storage (HDD)
                config = "/persist/opt/services";  # Service configs
                merged = "/mnt/user";    # Merged storage view
            };
            
            # Enable service categories gradually to find working ones
            networking.enable = true;      # Tailscale, Syncthing, etc.
            dashboard.enable = true;       # Homepage dashboard
            media.enable = true;           # Jellyfin, Navidrome, etc.
            arr.enable = true;             # Sonarr, Radarr, Prowlarr, etc.
            productivity.enable = true;    # Vaultwarden, Miniflux, Paperless, etc.
            cloud.enable = true;           # Immich, Nextcloud, etc.
            utility.enable = true;         # Uptime Kuma, etc.
            downloads.enable = true;       # Deluge, etc.
            backup.enable = true;          # Backup services
            smarthome.enable = true;       # Home Assistant, etc.
            
            # Disable specific failing services
            networking.syncthing.enable = false;        # Missing /mnt/data/syncthing
            networking.rustdesk-server.enable = false;  # Missing relay server config
            productivity.calibre.enable = false;        # Missing library directory
            productivity.radicale.enable = false;       # Missing htpasswd file
            
            # Enable Cloudflare Tunnel for external access
            networking.cloudflare-tunnel = {
              enable = true;
              tunnelId = config.sops.secrets."cloudflare/tunnel_id".path;
              tunnelToken = config.sops.secrets."cloudflare/tunnel_token".path;
              ingress = {
                "starcommand.live" = "http://127.0.0.1:443";
                "*.starcommand.live" = "http://127.0.0.1:443";
              };
            };
            
            # 🛡️ Fail2Ban + Cloudflare Protection (optional but recommended)
            # utility.fail2ban-cloudflare = {
            #     enable = true;
            #     apiKeyFile = "/etc/nixos/secrets/cloudflare-firewall.key";
            #     zoneId = "9c26b00054e2c3c833cd6ded804ef076";  # Your actual Zone ID
            # };
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
