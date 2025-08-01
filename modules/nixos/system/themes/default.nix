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
  cfg = config.${namespace}.system.themes;
  
  # Available themes with their packages
  availableThemes = {
    whitesur = {
      name = "WhiteSur";
      description = "macOS Big Sur inspired theme";
      packages = with pkgs; [
        whitesur-gtk-theme
        whitesur-icon-theme
        whitesur-cursors
      ];
      gtkTheme = "WhiteSur";
      iconTheme = "WhiteSur";
      cursorTheme = "WhiteSur-cursors";
    };
    # Add more themes here as needed
    # catppuccin = {
    #   name = "Catppuccin";
    #   description = "Soothing pastel theme";
    #   packages = with pkgs; [
    #     catppuccin-gtk
    #     catppuccin-cursors
    #   ];
    #   gtkTheme = "Catppuccin-Mocha";
    #   iconTheme = "Papirus-Dark";
    #   cursorTheme = "Catppuccin-Mocha-Dark-Cursors";
    # };
  };
  
  # Create enum from available themes
  themeEnum = types.enum (["none"] ++ (builtins.attrNames availableThemes));
in
{
  options.${namespace}.system.themes = with types; {
    enable = mkBoolOpt false "Enable theme system";
    selected = mkOpt themeEnum "none" ''
      The theme to apply.
      
      Available themes:
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: theme: "  - ${name}: ${theme.description}") availableThemes)}
      
      Example:
      ```nix
      FTS-FLEET = {
        system.themes = {
          enable = true;
          selected = "whitesur";
        };
      };
      ```
    '';
  };

  config = mkIf (cfg.enable && cfg.selected != "none") {
    # Get the selected theme configuration
    _module.args.selectedTheme = availableThemes.${cfg.selected};
    
    # Install theme packages
    environment.systemPackages = with pkgs; selectedTheme.packages;
    
    # Apply theme configuration
    environment.sessionVariables = {
      GTK_THEME = selectedTheme.gtkTheme;
      XCURSOR_THEME = selectedTheme.cursorTheme;
    };
    
    # Configure GTK theme
    gtk = {
      enable = true;
      theme = {
        name = selectedTheme.gtkTheme;
        package = selectedTheme.packages;
      };
      iconTheme = {
        name = selectedTheme.iconTheme;
        package = selectedTheme.packages;
      };
      cursorTheme = {
        name = selectedTheme.cursorTheme;
        package = selectedTheme.packages;
      };
    };
  };
}
