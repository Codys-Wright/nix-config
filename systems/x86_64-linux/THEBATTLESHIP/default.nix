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
        desktop.type = "gnome";  # Primary desktop environment
        desktop.environments = ["kde" "gnome"];  # Available desktop environments for theming
        
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
        
       
    };

    # Additional system packages (GUI and specific tools)
    environment.systemPackages = with pkgs; [
        brave
        vscode
        snowfallorg.frost
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
