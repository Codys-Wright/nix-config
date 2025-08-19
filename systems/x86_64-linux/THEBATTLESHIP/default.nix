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
	./hardware-configuration.nix
    ];

    # Disk configuration
    FTS-FLEET.system.disk = {
      enable = true;
      type = "btrfs-impermanence";
      device = "/dev/nvme2n1";
      withSwap = true;
      swapSize = "205";  # 205GB swap partition for full hibernation
    };
    
    # Bootloader configuration
    # Alternative: Use systemd-boot instead of GRUB (often more reliable)
    FTS-FLEET.system.boot.systemd-boot = enabled;

    # Facter configuration
    facter.reportPath =
        if builtins.pathExists ./facter.json then
            ./facter.json
        else
            throw "Have you forgotten to run nixos-anywhere with `--generate-hardware-config nixos-facter ./facter.json`?";

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
        initialPassword = "";
    };

    # FTS-FLEET namespace configuration
    FTS-FLEET = {
        bundles.common = enabled;
        bundles.cli = enabled;
        music.production = enabled;
        gaming = enabled;
        desktop.type = "gnome";  # Primary desktop environment
        desktop.environments = ["kde" "gnome"];  # Available desktop environments for theming
        
        # Programs
        programs.nh = enabled;
        
        # GPU configuration
        gpu = {
          enable = true;
          type = "nvidia";
        };
        
        # System kernel configuration
        system.kernel = enabled;
        
        hardware.cuda = disabled;


        # Audio device configuration
        hardware.audio = {
            enable = true;
            pipewire = {
                enable = true;
                sampleRate = 48000;
                bufferSize = 128;
                minBufferSize = 128;
                maxBufferSize = 128;
            };
            wireguard = {
                enable = true;
                systemOutput = "alsa_card.usb-Yamaha_Corporation_Yamaha_TF-00";
                dawOutput = "alsa_card.usb-Yamaha_Corporation_Yamaha_TF-00";
                defaultInput = "alsa_card.usb-Yamaha_Corporation_Yamaha_TF-00";
            };
            raysession = enabled;
        };
        
        # system.themes.stylix = enabled;
        services.ssh = {
            enable = true;
            allowRootLogin = true;
            rootKeys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKXs4YKtweDc2OcDDE6LoENPqQc8W79QQczfK9XErG4z CodyWright@THEBATTLESHIP"
            ];
        };
        
        # Enable fonts with Apple Color Emoji
        system.fonts = {
            enable = true;
            enableAppleEmoji = true;
        };
        
        # 🏠 Selfhost Configuration
        services.selfhost = {
            enable = true;
            baseDomain = "starcommand.live";
            # Enable ACME for local SSL certificates
            acme.email = "acodywright@gmail.com";
            cloudflare.dnsCredentialsFile = "/etc/nixos/secrets/cloudflare-dns.env";
            
            # Storage configuration
            mounts = {
                fast = "/mnt/cache";     # Fast storage (SSD)
                slow = "/mnt/storage";   # Slow storage (HDD)
                config = "/persist/opt/services";  # Service configs
                merged = "/mnt/user";    # Merged storage view
            };
            
            # Minimal service selection for initial setup
            networking.enable = true;      # Tailscale, Syncthing, etc.
            dashboard.enable = true;       # Homepage dashboard
            media.jellyfin.enable = true;  # Media server (easy to test)
            
            # 🛡️ Fail2Ban + Cloudflare Protection (optional but recommended)
            # utility.fail2ban-cloudflare = {
            #     enable = true;
            #     apiKeyFile = "/etc/nixos/secrets/cloudflare-firewall.key";
            #     zoneId = "9c26b00054e2c3c833cd6ded804ef076";  # Your actual Zone ID
            # };
        };

        # 🌐 Cloudflare Tunnel Configuration (Declarative!)
        services.selfhost.networking.cloudflare-tunnel = {
            enable = true;
            tunnelId = "06ec96ae-5cd0-4c7c-8a5c-5cba53f764e8";
            tunnelToken = "eyJhIjoiZDliZWE2ODdmNWE2YTE5YTNjNzZhMTk1NWZiNzU5NTIiLCJ0IjoiMDZlYzk2YWUtNWNkMC00YzdjLThhNWMtNWNiYTUzZjc2NGU4IiwicyI6IlpqY3lNekF6TldVdE5XTTRNeTAwTkRRMExXRmpOVFl0T0Rrek5HTTRPRFZsT0dNMyJ9";
            
            ingress = {
                # Homepage dashboard on root domain
                "starcommand.live" = "http://127.0.0.1:3000";
                
                # Individual services
                "jellyfin.starcommand.live" = "http://127.0.0.1:8096";
                "syncthing.starcommand.live" = "http://127.0.0.1:8384";
                
                # Future services (uncomment as you enable them)
                # "photos.starcommand.live" = "http://127.0.0.1:3001";     # Immich
                # "music.starcommand.live" = "http://127.0.0.1:4533";      # Navidrome
                # "grafana.starcommand.live" = "http://127.0.0.1:3030";    # Grafana
            };
        };
       
    };

    # Additional system packages (GUI and specific tools)
    environment.systemPackages = with pkgs; [
        brave
        vscode
	code-cursor
	opencode
	gemini-cli
        snowfallorg.frost
        zed-editor
        whitesur-wallpapers
    ];

    # Add overlay to make custom packages available
    nixpkgs.overlays = [
        (final: prev: {
          whitesur-wallpapers = inputs.self.packages.${prev.system}.whitesur-wallpapers;
        })
      ];

    # Nix configuration to allow deployment
    nix.settings.trusted-users = ["root" "@wheel"];

    system.stateVersion = "24.05";
} 
