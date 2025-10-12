{
  config,
  lib,
  pkgs,
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
      browsers = enabled;
      # desktop.hyprland = enabled; # Disabled - using desktop module
      office = enabled;
      music = enabled;
      # music-production = enabled; # Disabled - using system-level music production
    };

    # Desktop configuration - using individual modules
    desktop = {
      hyprland = enabled; # Enable Hyprland desktop environment
      caelestia = enabled; # Uncomment to use Caelestia instead
    };

    

    coding = {
      enable = true;
      lang = enabled;
      editor = enabled;
      cli = enabled;
      shell = enabled;
      tools = enabled;
    };

   

app = {
        misc = {
            rustdesk-client.enable = true;
        };
    };

    config.user = {
      enable = true;
      name = "cody";
      fullName = "Cody Wright";
      email = "acodywright@gmail.com"; # Update this with your actual email
    };

    communications = {
      discord = {
        enable = true;
        useEquibop = true;
      };
    };

    # Recording tools and OBS Studio
    recording = {
      enable = true;
    };

    # Unified theme system
    theme = {
      enable = true;
      preset = "whitesur";
      polarity = "dark";
      # WhiteSur-specific options
      whitesur = {
        stylix.enable = true; # Enable stylix for theming
        opacity = "25"; # Panel opacity: 15, 25, 35, 45, 55, 65, 75, 85
        panelHeight = "40"; # Panel height: 32, 40, 48, 56, 64
        activitiesIcon = "colorful"; # Activities icon: standard, colorful, white, ubuntu
        smallerFont = false; # Use 10pt instead of 13pt font
        showAppsNormal = false; # Use normal show apps button style
        montereyStyle = false; # Use Monterey style instead of BigSur
        highDefinition = false; # Use high-DPI size
        libadwaita = false; # Enable GTK4/libadwaita theming
        fixedAccent = false; # Use fixed accent colors
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

  # Stylix configuration - enable theming without wallpaper management
  stylix = {
    enable = true;
    # Don't set stylix.image to avoid conflicts with mpvpaper
  };

  # Add Apple Color Emoji font to home packages
  home.packages = with pkgs; [
    inputs.apple-emoji-linux.packages.x86_64-linux.default
    chawan
                mpvpaper
  ];
 
  programs.chawan.enable = true;

# mpvpaper animated wallpaper
programs.mpvpaper = {
  enable = true;
  pauseList = "";
  stopList = "";
};

# Custom systemd service for mpvpaper with specific video
systemd.user.services.mpvpaper-custom = {
  Unit = {
    Description = "mpvpaper animated wallpaper";
    After = [ "graphical-session.target" ];
    ConditionEnvironment = "WAYLAND_DISPLAY";
  };
  Service = {
    Type = "simple";
    ExecStart = "${pkgs.mpvpaper}/bin/mpvpaper -o \"no-audio --loop\" ALL /home/cody/Images/midnight-glow-over-peaks.3840x2160.mp4";
    Restart = "always";
    RestartSec = 3;
    Slice = "session.slice";
  };
  Install = {
    WantedBy = [ "graphical-session.target" ];
  };
};


 
  # Configure fontconfig for Apple Color Emoji
  fonts.fontconfig.enable = true;

  # Hyprland monitor configuration
  wayland.windowManager.hyprland.settings.monitor = [
    "DP-3,2560x1440@180.00,0x0,1.00"
    "DP-4,2560x1440@180.00,2560x0,1.00"
    "DP-5,2560x1440@143.91,5120x0,1.00"
  ];

  # Shell aliases for nix search tools
  programs.bash.shellAliases = {
    ns = "nix-search-tv print | fzf --preview 'nix-search-tv preview {}' --scheme history --preview-window=up:50%";
    voyager = "ssh cody@100.96.79.26";
  };

  programs.zsh.shellAliases = {
    ns = "nix-search-tv print | fzf --preview 'nix-search-tv preview {}' --scheme history --preview-window=up:50%";
    voyager = "ssh cody@100.96.79.26";
  };

  programs.fish.shellAliases = {
    ns = "nix-search-tv print | fzf --preview 'nix-search-tv preview {}' --scheme history --preview-window=up:50%";
    voyager = "ssh cody@100.96.79.26";
  };


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
