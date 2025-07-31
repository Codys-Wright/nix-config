{
  modulesPath,
  lib,
  pkgs,
  ...
} @ args:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk-config.nix
  ];
  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  services.openssh.enable = true;

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

    # Add any other packages you want
  ];

  programs = {
  };

  # KDE Plasma Desktop Environment
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  
  # Auto-login for KDE Plasma
  services.displayManager.sddm.settings = {
    Autologin = {
      User = "cody";
      Session = "plasma";
    };
  };

  # Enable sound with pipewire
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Stylix theming configuration
  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-medium.yaml";
    
    image = ./Windows-11-PRO.png;
    
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

  users.users.root.openssh.authorizedKeys.keys =
  [
    # Your SSH key for VM access
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKXs4YKtweDc2OcDDE6LoENPqQc8W79QQczfK9XErG4z CodyWright@THEBATTLESHIP"
  ] ++ (args.extraPublicKeys or []); # this is used for unit-testing this module and can be removed if not needed

  # Backup user for emergency access
  users.users.cody = {
    isNormalUser = true;
    password = ""; # Simple password for emergency access
    uid = 1001;
    extraGroups = [ "wheel" "networkmanager" ];
    openssh.authorizedKeys.keys = [
      # Your SSH key for backup access
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKXs4YKtweDc2OcDDE6LoENPqQc8W79QQczfK9XErG4z CodyWright@THEBATTLESHIP"
    ];
  };

  system.stateVersion = "24.05";
}
