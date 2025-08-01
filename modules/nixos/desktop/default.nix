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
    # Primary desktop environment
    type = mkOpt (types.enum [ "hyprland" "kde" "gnome" "none" ]) "none" ''
      The primary desktop environment to use.
      
      Options:
      - hyprland: Modern Wayland-based tiling window manager
      - kde: KDE Plasma 6 desktop environment
      - gnome: GNOME desktop environment
      - none: No desktop environment (headless/server)
      
      Example:
      ```nix
      ${namespace} = {
        desktop.type = "kde";
      };
      ```
    '';
    
    # Multiple desktop environments support
    environments = mkOpt (types.listOf (types.enum [ "hyprland" "kde" "gnome" ])) [] ''
      List of desktop environments to enable (for theming and packages).
      This allows multiple desktop environments to be available for theming.
      
      Example:
      ```nix
      ${namespace} = {
        desktop.environments = [ "gnome" "kde" ];
      };
      ```
    '';
    
    autoLogin = mkOpt (types.submodule {
      options = {
        enable = mkBoolOpt false "Enable automatic login";
        user = mkOpt types.str "cody" "User to auto-login";
      };
    }) {
      enable = true;
      user = "cody";
    } "Auto-login configuration";
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
    
    # Auto-login configuration based on desktop type
    services = mkIf cfg.autoLogin.enable (mkMerge [
      # GNOME auto-login
      (mkIf (cfg.type == "gnome") {
        displayManager.gdm.settings = {
          daemon = {
            AutomaticLogin = cfg.autoLogin.user;
            AutomaticLoginEnable = true;
          };
        };
      })
      # KDE auto-login
      (mkIf (cfg.type == "kde") {
        displayManager.sddm.settings = {
          Autologin = {
            User = cfg.autoLogin.user;
            Session = "plasma-x11";
          };
        };
      })
      # Hyprland auto-login
      (mkIf (cfg.type == "hyprland") {
        displayManager.gdm.settings = {
          daemon = {
            AutomaticLogin = cfg.autoLogin.user;
            AutomaticLoginEnable = true;
          };
        };
      })
    ]);
  };
} 