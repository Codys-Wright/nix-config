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
        ../../../disk-config.nix
    ];

    # Disko disk configuration for VM
    disko.devices.disk.disk1.device = "/dev/vda";

    # Facter configuration
    facter.reportPath =
        if builtins.pathExists ./facter.json then
            ./facter.json
        else
            throw "Have you forgotten to run nixos-anywhere with `--generate-hardware-config nixos-facter ./facter.json`?";

    # Configure Home Manager to handle file conflicts with unique identifier
    home-manager.backupFileExtension = "bak-2025-07-31";

    # Configure the cody user with Home Manager
    snowfallorg.users.cody = {
        create = true;
        admin = true;
        home = {
            enable = true;
            path = "/home/cody";
        };
    };

    # FTS-FLEET configuration
    FTS-FLEET = {
        config = {
            user = {
                name = "cody";
                extraGroups = [
                    "wheel"
                    "networkmanager"
                    "audio"
                    "video"
                    "libvirtd"
                    "docker"
                    "render"
                ];
            };
            nix = enabled;
        };
        hardware = {
            nvidia = disabled;
            cuda = disabled;
            bluetooth = enabled;
            sound = enabled;
        };
        services = {
            ssh = enabled;
            openssh = enabled;
            pipewire = enabled;
            xserver = enabled;
            displayManager = {
                sddm = enabled;
            };
            desktopManager = {
                plasma6 = enabled;
            };
        };
        system = {
            boot = {
                grub = enabled;
            };
            locale = enabled;
            xkb = enabled;
        };
        programs = {
            home-manager = enabled;
            stylix = enabled;
        };
    };

    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;

    # Basic system packages
    environment.systemPackages = with pkgs; [
        curl
        gitMinimal
        vim
        brave
        kitty
        neovim
        tmux
        zsh
        git
        vscode
        btop
    ];

    # Auto-login for KDE Plasma
    services.displayManager.sddm.settings = {
        Autologin = {
            User = "cody";
            Session = "plasma";
        };
    };

    # Stylix theming configuration
    stylix = {
        enable = true;
        base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-medium.yaml";
        
        image = ../../../Windows-11-PRO.png;
        
        cursor = {
            package = pkgs.bibata-cursors;
            name = "Bibata-Modern-Ice";
            size = 24;
        };
        
        fonts = {
            monospace = {
                package = pkgs.nerd-fonts.jetbrains-mono;
                name = "JetBrainsMono Nerd Font Mono";
            };
            sansSerif = {
                package = pkgs.dejavu_fonts;
                name = "DejaVu Sans";
            };
            serif = {
                package = pkgs.dejavu_fonts;
                name = "DejaVu Serif";
            };
            emoji = {
                package = pkgs.noto-fonts-emoji;
                name = "Noto Color Emoji";
            };
        };
        
        polarity = "dark";
    };

    # SSH keys for root user
    users.users.root.openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKXs4YKtweDc2OcDDE6LoENPqQc8W79QQczfK9XErG4z CodyWright@THEBATTLESHIP"
    ];

    # Backup user for emergency access
    users.users.cody = {
        isNormalUser = true;
        password = ""; # Simple password for emergency access
        uid = 1001;
        extraGroups = [ "wheel" "networkmanager" ];
        openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKXs4YKtweDc2OcDDE6LoENPqQc8W79QQczfK9XErG4z CodyWright@THEBATTLESHIP"
        ];
    };

    system.stateVersion = "24.05";
} 