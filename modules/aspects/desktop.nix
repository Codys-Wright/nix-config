# Desktop aspect - provides all desktop environments and enables SDDM
# This is a parametric aspect that includes all desktop environments
# and allows configuring a default desktop environment and display manager
{
  den,
  lib,
  ...
}:
let
  description = ''
    Desktop environment aspect - includes all desktop environments and display managers.

    Can optionally take named parameters for granular control:
      den.aspects.desktop
      den.aspects.desktop { environment = "hyprland"; }
      den.aspects.desktop {
        environment = "xfce";
        display-manager = { type = "sddm"; theme = "minecraft"; };
        bootloader = { type = "grub"; theme = "minecraft-double-menu"; };
      }

    Available options:
    - environment: hyprland, xfce, kde, gnome
    - display-manager: { type = "sddm"|"gdm"; theme = "minecraft"|null }
    - bootloader: { type = "grub"; theme = "minecraft"|"minecraft-double-menu"|null }
  '';

  baseIncludes = [
    # Desktop keybind abstractions
    den.aspects.desktop-keybinds

    # All desktop environments
    den.aspects.hyprland-keybinds
    den.aspects.xfce-desktop
    den.aspects.kde-desktop
    den.aspects.gnome-desktop

    # Display managers and themes
    den.aspects.sddm
    den.aspects.sddm.minesddm
    den.aspects.gdm

    # Bootloaders and themes
    den.aspects.grub
    den.aspects.grub.minegrub
    den.aspects.grub.minegrub-world-sel
    den.aspects.grub.minegrub-double-menu
  ];

  # Extract desktop environment, display manager, and bootloader settings from arguments
  getDesktopConfig = arg:
    if arg == null || arg == { } then
      {
        environment = null;
        displayManager = { type = "sddm"; theme = null; };
        bootloader = null;
      }
    else if lib.isAttrs arg then
      {
        environment = arg.environment or arg.default or null;
        displayManager = if arg.display-manager != null then arg.display-manager else { type = "sddm"; theme = null; };
        bootloader = arg.bootloader or null;
      }
    else
      throw "desktop: argument must be an attribute set";

  # Get the default session name for a desktop environment
  getDefaultSession = desktop: {
    hyprland = "hyprland";
    xfce = "xfce";
    kde = "plasma";
    gnome = "gnome";
  }.${desktop} or desktop;

  # Configure display manager based on selection
  configureDisplayManager = displayManagerConfig: desktop: nixos: {
    services.displayManager = {
      # Set default session based on desktop environment
      defaultSession = lib.mkIf (desktop != null) (getDefaultSession desktop);

      # Configure the selected display manager with theme
      sddm = lib.mkIf (displayManagerConfig.type == "sddm") {
        enable = true;
        wayland.enable = true;
        theme = lib.mkIf (displayManagerConfig.theme == "minecraft") "minesddm";
      };
      gdm = lib.mkIf (displayManagerConfig.type == "gdm") {
        enable = true;
      };
    } // nixos.services.displayManager or {};
  };

  # Configure bootloader based on selection
  configureBootloader = bootloaderConfig: nixos: lib.mkIf (bootloaderConfig != null) (
    lib.mkMerge [
      {
        boot.loader.grub = {
          enable = lib.mkIf (bootloaderConfig.type == "grub") true;
        } // lib.optionalAttrs (bootloaderConfig.theme == "minecraft") {
          # Minecraft theme configuration
          minegrub-theme = {
            enable = true;
            splash = "100% Flakes!";
            background = "background_options/1.8  - [Classic Minecraft].png";
            boot-options-count = 4;
          };
        } // lib.optionalAttrs (bootloaderConfig.theme == "minecraft-double-menu") {
          # Minecraft double menu configuration
          minegrub-theme.enable = true;
          minegrub-world-sel.enable = true;
          timeoutStyle = "menu";
          theme = "minegrub-world-selection";
        };
      }
      nixos
    ]
  );
in
{
  den.aspects.desktop = den.lib.parametric {
    inherit description;
    includes = baseIncludes ++ [
      ({ nixos, ... }: arg:
        let
          config = getDesktopConfig arg;
          displayManagerConfig = configureDisplayManager config.displayManager config.environment nixos;
          bootloaderConfig = configureBootloader config.bootloader nixos;
        in
        lib.mkMerge [
          # Configure display manager (always enabled)
          displayManagerConfig
          # Configure bootloader if specified
          bootloaderConfig
        ]
      )
    ];
  };
}

