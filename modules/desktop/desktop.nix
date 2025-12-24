# Desktop facet - Provides access to different desktop components
{FTS, ...}: {
  FTS.desktop.description = ''
    Desktop configuration with support for environments, display managers, and bootloaders.

    Usage as router:
      (<FTS/desktop> { environment = { default = "hyprland"; }; displayManager = { auto = true; }; })

    Direct access to specific components:
      (<FTS/desktop/environment> { default = "gnome"; includes = ["hyprland" "kde"]; })
      (<FTS/desktop/display-manager> { default = "gdm"; })
  '';

  # Make desktop callable as a router function
  FTS.desktop = {};
}
