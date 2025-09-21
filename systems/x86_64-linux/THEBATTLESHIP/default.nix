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
        # AudioHaven - imports all modules
        inputs.audiohaven.nixosModules.audiohaven
	./hardware-configuration.nix
        
  
    ];

    # Testing configuration
    # testing.mkwindowsapp.enable = true;
    
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

        # Enable SOPS for secrets management
        programs.sops = enabled;
        music.production = enabled;
        # gaming = enabled;  # Disabled to allow custom NVIDIA driver version
        desktop.type = "gnome";  # Primary desktop environment
        desktop.environments = ["kde" "gnome"];  # Available desktop environments for theming
       gaming = enabled;
        # Programs
        programs.nh = enabled;
        programs.snowfall-flake = enabled;
        programs.protonvpn-gui = enabled;
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
        
        # Development
        development = enabled;
        
        # GPU configuration
        gpu = {
          enable = true;
          type = "nvidia";
        };
        
        # System kernel configuration
        system.kernel = enabled;
        
        # Hardware storage configuration for udisks2 auto-mounting
        hardware.storage = enabled;
        
        hardware.cuda = disabled;


        services.airplay = enabled;


        # Remote Desktop Services
        services.remote-desktop = {
            moonlight.enable = true;
            sunshine.enable = true;
        };


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
        
        system.themes.stylix = disabled;
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
        
        # Local hosts for accessing starcommand services
        services.selfhost.networking.local-hosts = {
            enable = true;
            targetIP = "192.168.1.46";  # starcommand IP
            domains = [
                "starcommand.live"
                "jdownloader.starcommand.live"
                "jellyfin.starcommand.live"
                "deluge.starcommand.live"
                "qbittorrent.starcommand.live"
                "sabnzbd.starcommand.live"
                "slskd.starcommand.live"
                "home.starcommand.live"
                "bin.starcommand.live"
                "audiobooks.starcommand.live"
                "bazarr.starcommand.live"
                "jellyseerr.starcommand.live"
                "lidarr.starcommand.live"
                "mealie.starcommand.live"
                "nextcloud.starcommand.live"
                "prowlarr.starcommand.live"
                "radarr.starcommand.live"
                "readarr.starcommand.live"
                "sonarr.starcommand.live"
                "syncthing.starcommand.live"
            ];
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
                wineWowPackages.yabridge
                whitesur-wallpapers
                ntfs3g  # For NTFS support
                gvfs
                inputs.self.packages.${system}.lyp  # LilyPond package manager
                lilypond-with-fonts  # LilyPond music typesetting system
                gnome.gvfs
                cifs-utils
                carla
                auto-patchelf
                gtk3
                gtk4
                zathura
                
                # Reaper (with GTK3 fix via overlay)
                reaper
                
                # LilyPond package manager
                inputs.self.packages.${pkgs.system}.lyp
                
                # Audio Haven packages for testing
                inputs.audiohaven.packages.${pkgs.system}.YabridgeSystemSetup
                inputs.audiohaven.packages.${pkgs.system}.algonaut-atlas
                # inputs.audiohaven.packages.${pkgs.system}.omnisphere
        ];

    # Audio Haven configuration
    audiohaven.plugins.effects.fabfilter = {
        enable = true;
        enableYabridge = true;
    };

    audiohaven.plugins.effects.seventhheaven = {
        enable = true;
        enableYabridge = true;
    };

    audiohaven.plugins.instruments.omnisphere = {
        enable = true;
        enableYabridge = true;
        steamPath = "/run/media/cody/AUDIO HAVEN/SAMPLE LIBRARIES - INSTRUMENTS/Spectrasonics/STEAM";
    };

    audiohaven.plugins.instruments.algonaut-atlas = {
        enable = true;
        enableYabridge = true;
        atlasPath = "/run/media/cody/AUDIO HAVEN/SAMPLE LIBRARIES - INSTRUMENTS/Algonaut/Atlas";
        installerPath = "/home/cody/Documents/AudioHaven Software/algonaut-atlas";
    };

    audiohaven.plugins.instruments.addictive-drums = {
        enable = true;
        enableYabridge = true;
        installerPath = "/home/cody/Documents/AudioHaven Software/INSTRUMENTS/Drums/XLN Audio - Addictive Drums 2 Complete v2.5.2.1";
    };

    # Add overlay to make custom packages available
    nixpkgs.overlays = [
        (final: prev: {
          whitesur-wallpapers = inputs.self.packages.${prev.system}.whitesur-wallpapers;
        })
    ];

    # 10Gb network configuration for direct connection to starcommand
    networking.interfaces.enp12s0 = {
        ipv4.addresses = [{
            address = "10.0.0.1";
            prefixLength = 24;
        }];
    };

    # SMB client configuration for accessing starcommand shares
    services.samba = {
        enable = true;
        package = pkgs.samba;
    };

    # Configure GVFS for network share discovery
    services.gvfs.enable = true;


    # Nix configuration to allow deployment
    nix.settings.trusted-users = ["root" "@wheel"];

    system.stateVersion = "24.05";
} 
