{
  options,
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.desktop.kde;
in
{
  options.${namespace}.desktop.kde = with types; {
    enable = mkBoolOpt false ''
      Whether or not to use KDE Plasma as the desktop environment.
      
      When enabled, this module will:
      - Enable X11 server
      - Configure SDDM display manager
      - Enable KDE Plasma 6 desktop environment
      - Set up basic KDE services and applications
      
      Example:
      ```nix
      ${namespace} = {
        desktop.kde = enabled;
      };
      ```
    '';
  };

  config = mkIf cfg.enable {
    # Essential Plasma 6 packages
    environment.systemPackages = with pkgs; [
      # Core Plasma 6 packages
      kdePackages.plasma-desktop
      kdePackages.kdeplasma-addons
      kdePackages.plasma-workspace
      kdePackages.plasma-nm
      kdePackages.kde-gtk-config
      
      # Audio and multimedia
      kdePackages.plasma-pa
      
      # Essential KDE applications
      kdePackages.kate
      kdePackages.kcalc
      kdePackages.dolphin
      kdePackages.konsole
      kdePackages.gwenview
      kdePackages.spectacle
      kdePackages.okular
      kdePackages.ark
      
      # Creative applications
      kdePackages.kdenlive  # Qt 6 version
      krita  # Separate package
      
      # Qt 6 packages for platform plugins
      qt6.full
      qt6.qtbase
      qt6.qtdeclarative
      qt6.qtwayland
    ];

    # Qt environment configuration
    environment.sessionVariables = {
      QT_QPA_PLATFORM = "xcb";
      QT_QPA_PLATFORMTHEME = "kde";
      QT_STYLE_OVERRIDE = "kde";
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";
      QT_SCALE_FACTOR = "1";
    };

    # X11 and display manager configuration
    services = {
      xserver = {
        enable = true;
        # Ensure X11 is properly configured
        layout = "us";
        xkbVariant = "";
        # Enable touchpad support
        libinput.enable = true;
      };
      
      displayManager = {
        sddm = {
          enable = true;
          wayland.enable = true;
          # Ensure SDDM is properly configured
          settings = {
            General = {
              DisplayServer = "x11";
              GreeterEnvironment = "QT_QPA_PLATFORM=xcb";
            };
            Theme = {
              Current = "breeze";
            };
          };
        };
      };
      
      desktopManager = {
       
      };
      
      # Additional services
      flatpak.enable = true;
      desktopManager.plasma6.enable = true;
    };
  };
}
