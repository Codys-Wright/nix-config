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
  cfg = config.${namespace}.desktop.gnome.themes;
  
  # Available themes for GNOME
  availableThemes = {
    whitesur = {
      name = "WhiteSur";
      description = "macOS Big Sur inspired theme";
      module = ./whitesur;
    };
    # Add more themes here as needed
    # catppuccin = {
    #   name = "Catppuccin";
    #   description = "Soothing pastel theme";
    #   module = ./catppuccin;
    # };
  };
  
  # Create enum from available themes
  themeEnum = types.enum (["none"] ++ (builtins.attrNames availableThemes));
in
{
  options.${namespace}.desktop.gnome.themes = with types; {
    enable = mkBoolOpt false "Enable GNOME theme system";
    selected = mkOpt themeEnum "none" ''
      The theme to apply to GNOME.
      
      Available themes:
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: theme: "  - ${name}: ${theme.description}") availableThemes)}
      
      Example:
      ```nix
      FTS-FLEET = {
        desktop.gnome.themes = {
          enable = true;
          selected = "whitesur";
        };
      };
      ```
    '';
  };

  config = mkIf (cfg.enable && cfg.selected != "none") {
    # Import the selected theme module
    imports = [
      availableThemes.${cfg.selected}.module
    ];
  };
} 