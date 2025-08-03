{
  config,
  lib,
  osConfig,
  namespace,
  inputs,
  ...
}:
with lib;
with lib.${namespace};
{
  snowfallorg.user.enable = true;
  
 
  
  FTS-FLEET = {
    bundles = {
      common = enabled;
      shell = enabled;
      browsers = enabled;
      # desktop.hyprland = enabled; # Disabled - using KDE
      development = enabled;
      office = enabled;
      music = enabled;
      # music-production = enabled; # Disabled - using system-level music production
    };

    programs = {
      git = enabled;
      zed-editor = enabled;
    };

    
    config.user = {
      enable = true;
      name = "cody";
      fullName = "Cody Wright";
      email = "cody@example.com"; # Update this with your actual email
    };

    communications = {
      discord = {
        enable = true;
        useEquibop = true; 
      };
    };

    
    
    # Unified theme system
    theme = {
      enable = true;
      preset = "whitesur";
      polarity = "dark";
      # WhiteSur-specific options
      whitesur = {
        opacity = "25";           # Panel opacity: 15, 25, 35, 45, 55, 65, 75, 85
        panelHeight = "40";       # Panel height: 32, 40, 48, 56, 64
        activitiesIcon = "colorful"; # Activities icon: standard, colorful, white, ubuntu
        smallerFont = false;      # Use 10pt instead of 13pt font
        showAppsNormal = false;   # Use normal show apps button style
        montereyStyle = false;    # Use Monterey style instead of BigSur
        highDefinition = false;   # Use high-DPI size
        libadwaita = false;       # Enable GTK4/libadwaita theming
        fixedAccent = false;      # Use fixed accent colors
      };
      targets = {
        colors = enabled;
        fonts = enabled;
        icons = enabled;
        cursor = enabled;
        gtk = enabled;
        shell = enabled;
        wallpaper = enabled;
      };
    };
  };

  # Add Apple Color Emoji font to home packages
  home.packages = with pkgs; [
    inputs.apple-emoji-linux.packages.x86_64-linux.default
  ];

  # Configure fontconfig for Apple Color Emoji
  fonts.fontconfig.enable = true;

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = lib.mkDefault (osConfig.system.stateVersion or "24.05");
} 