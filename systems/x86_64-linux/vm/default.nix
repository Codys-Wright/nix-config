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

    # FTS-FLEET namespace configuration
    FTS-FLEET = {
        desktop.kde = enabled;
        hardware.audio = enabled;
        hardware.bluetooth = enabled;
        hardware.networking = enabled;
        system.themes.stylix = enabled;
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
        snowfallorg.frost
    ];

    # Auto-login for KDE Plasma
    services.displayManager.sddm.settings = {
        Autologin = {
            User = "cody";
            Session = "plasma";
        };
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