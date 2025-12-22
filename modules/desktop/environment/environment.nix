# Desktop environment facet - Provides access to different desktop environments
{FTS, ...}: {
  FTS.desktop._.environment.description = ''
    Desktop environment configuration with support for multiple DEs.

    Usage as router:
      (<FTS/desktop/environment> { default = "hyprland"; includes = ["gnome" "kde"]; })

    Direct access to specific environments:
      (<FTS/desktop/environment/gnome> { })
      (<FTS/desktop/environment/hyprland> { })
      (<FTS/desktop/environment/kde> { })
  '';

  # Make environment callable as a router function
  FTS.desktop._.environment = {};
}
