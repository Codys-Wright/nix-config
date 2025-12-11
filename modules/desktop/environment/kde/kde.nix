# KDE Plasma Desktop Environment
# Provides NixOS configuration for KDE Plasma with theme support
{
  den,
  lib,
  FTS,
  ...
}:
{
  # Base KDE desktop environment
  # Usage: (FTS.desktop._.environment._.kde { theme = "whitesur"; })
  FTS.desktop._.environment._.kde =
    {
      theme ? null,
      ...
    }@args:
    { class, aspect-chain }:
    let
      # Available KDE themes
      availableThemes = ["whitesur" "breeze"];
      
      # Validate theme if provided
      _ = if theme != null && !(builtins.elem theme availableThemes)
        then throw "kde: unknown theme '${theme}'. Available: ${builtins.concatStringsSep ", " availableThemes}"
        else null;
      
      # Theme includes
      themeIncludes = if theme == "whitesur" then [ FTS.desktop._.environment._.kde._.themes._.whitesur ]
        else if theme == "breeze" then [ FTS.desktop._.environment._.kde._.themes._.breeze ]
        else [];
    in
    {
      description = "KDE Plasma 6 desktop environment";
      
      includes = themeIncludes;

      nixos = {
        # Enable KDE Plasma 6 desktop manager
        services.desktopManager.plasma6.enable = true;
        
        # Don't set SSH askPassword (override default from plasma6 module)
        programs.ssh.askPassword = lib.mkForce "";

        # Enable KDE applications (optional, can be added as needed)
        # environment.systemPackages = with pkgs; [
        #   kdePackages.kate
        #   kdePackages.dolphin
        #   kdePackages.konsole
        # ];

        # Enable KDE Connect for phone integration
        # programs.kdeconnect.enable = true;

        # Enable Wayland support
        programs.xwayland.enable = true;
      };

      homeManager = { pkgs, lib, ... }: {
        # KDE-specific home-manager configuration
      };
    };
}
