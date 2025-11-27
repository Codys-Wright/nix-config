# Desktop aspect - provides all desktop environments and enables SDDM
# This is a single unified aspect that includes all desktop environments
# (Hyprland, XFCE, GNOME, KDE, etc.) and enables SDDM display manager
{
  den,
  ...
}:
{
  den.aspects.desktop = {
    description = "Desktop environment aspect - includes all desktop environments and enables SDDM";

    includes = [
      # Desktop keybind abstractions
      den.aspects.desktop-keybinds
      
      # All desktop environments
      den.aspects.hyprland-keybinds
      den.aspects.xfce-desktop
      den.aspects.kde-desktop
      den.aspects.gnome-desktop
      
      # SDDM display manager (base)
      den.aspects.sddm
    ];

    nixos = {
      # Enable Wayland support in SDDM
      services.displayManager.sddm.wayland.enable = true;
    };
  };
}

