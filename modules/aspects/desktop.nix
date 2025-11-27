# Desktop aspect - enables desktop environments and keybind abstractions
# This aspect includes the desktop keybind abstractions and can enable
# different desktop environments (Hyprland, XFCE, GNOME, KDE, etc.)
{
  den,
  ...
}:
{
  den.aspects.desktop = {
    description = "Desktop environment aspect - includes keybind abstractions and desktop environments";

    # Include the desktop keybind abstractions by default
    # Individual desktop environments can be enabled via includes
    includes = [
      den.aspects.desktop-keybinds
    ];
  };

  # Hyprland desktop environment
  den.aspects.desktop.hyprland = {
    description = "Hyprland desktop environment with keybind support";
    includes = [
      den.aspects.desktop
      den.aspects.hyprland-keybinds
    ];
  };

  # XFCE desktop environment
  den.aspects.desktop.xfce = {
    description = "XFCE desktop environment";
    includes = [
      den.aspects.desktop
      den.aspects.example._.xfce-desktop
    ];
  };

  # KDE Plasma 6 desktop environment
  den.aspects.desktop.kde = {
    description = "KDE Plasma 6 desktop environment";
    includes = [
      den.aspects.desktop
      den.aspects.kde-desktop
    ];
  };

  # KDE Plasma 6 with SDDM (Wayland)
  den.aspects.desktop.kde.with-sddm = {
    description = "KDE Plasma 6 desktop environment with SDDM display manager (Wayland)";
    includes = [
      den.aspects.desktop
      den.aspects.kde-desktop
      den.aspects.sddm.wayland
    ];
  };

  # GNOME desktop environment
  den.aspects.desktop.gnome = {
    description = "GNOME desktop environment";
    includes = [
      den.aspects.desktop
      den.aspects.gnome-desktop
    ];
  };

  # GNOME with GDM
  den.aspects.desktop.gnome.with-gdm = {
    description = "GNOME desktop environment with GDM display manager";
    includes = [
      den.aspects.desktop
      den.aspects.gnome-desktop
      den.aspects.gdm
    ];
  };

  # Future desktop environments can be added here:
  # den.aspects.desktop.sway = { ... };
  # den.aspects.desktop.i3 = { ... };
}

