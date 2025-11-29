# Desktop aspect - provides all desktop environments and enables SDDM
# This is a parametric aspect that includes all desktop environments
# and allows configuring a default desktop environment and display manager
{
  den,
  lib,
  FTS,
  ...
}:
let
  description = ''
    Desktop environment aspect - includes all desktop environments and display managers.

    Can optionally take named parameters for granular control:
      FTS.desktop
      FTS.desktop { environment = "hyprland"; }
      FTS.desktop {
        environment = "xfce";
        display-manager = { type = "sddm"; theme = "minecraft"; };
        bootloader = { type = "grub"; theme = "minecraft-double-menu"; };
      }

    Available options:
    - environment: hyprland, xfce, kde, gnome
    - display-manager: { type = "sddm"|"gdm"; theme = "minecraft"|null }
    - bootloader: { type = "grub"; theme = "minecraft"|"minecraft-double-menu"|null }
  '';

  # Get the default session name for a desktop environment
  getDefaultSession = desktop: {
    hyprland = "hyprland";
    xfce = "xfce";
    kde = "plasma";
    gnome = "gnome";
  }.${desktop} or desktop;

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

in
{
  FTS.desktop = {
    inherit description;
    includes = [
      # Desktop keybind abstractions
      FTS.desktop-keybinds

      # All desktop environments
      FTS.hyprland-keybinds
      FTS.hyprland
      FTS.xfce-desktop
      FTS.kde-desktop
      FTS.gnome-desktop

      # Display managers and themes (always include for flake-file.inputs)
      FTS.sddm
      FTS.sddm.minesddm
      FTS.gdm

      # Bootloaders and themes (always include for flake-file.inputs)
      FTS.grub
      FTS.grub.minegrub
      FTS.grub.minegrub-world-sel
      FTS.grub.minegrub-double-menu
    ];
    nixos = {
      services.displayManager = {
        defaultSession = null;
      };
    };

    # Make it work as a parametric provider when called with configuration
    __functor = self: arg:
      let
        config = getDesktopConfig arg;
      in
      {
        inherit (self) description;
        includes = self.includes;
        nixos = lib.mkMerge [
          {
            services.displayManager = {
              # Set default session based on desktop environment
              defaultSession = lib.mkIf (config.environment != null) (getDefaultSession config.environment);

              # Configure the selected display manager with theme
              sddm = lib.mkIf (config.displayManager.type == "sddm") {
                enable = true;
                wayland.enable = true;
                theme = lib.mkIf (config.displayManager.theme == "minecraft") "minesddm";
              };
              gdm = lib.mkIf (config.displayManager.type == "gdm") {
                enable = true;
              };
            };
          }
          (lib.mkIf (config.bootloader != null && config.bootloader.type == "grub") {
            boot.loader.grub = {
              enable = true;
              # Set devices to make the system bootable
              # Use nodev for VMs
              devices = [ "nodev" ];
            };
          })
        ];
      };
  };
}

