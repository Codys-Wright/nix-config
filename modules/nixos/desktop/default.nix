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
  cfg = config.${namespace}.desktop;
in
{
  options.${namespace}.desktop = with types; {
    type = mkOpt (types.enum [ "hyprland" "kde" "gnome" "none" ]) "none" ''
      The desktop environment to use.
      
      Options:
      - hyprland: Modern Wayland-based tiling window manager
      - kde: KDE Plasma 6 desktop environment
      - gnome: GNOME desktop environment
      - none: No desktop environment (headless/server)
      
      Example:
      ```nix
      FTS-FLEET = {
        desktop.type = "kde";
      };
      ```
    '';
  };

  config = mkIf (cfg.type != "none") {
    # Enable the appropriate desktop environment based on the type
    ${namespace}.desktop = mkMerge [
      (mkIf (cfg.type == "hyprland") {
        hyprland = enabled;
      })
      (mkIf (cfg.type == "kde") {
        kde = enabled;
      })
      (mkIf (cfg.type == "gnome") {
        gnome = enabled;
      })
    ];
  };
} 