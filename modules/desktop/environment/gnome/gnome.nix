# GNOME Desktop Environment
# Provides NixOS configuration for GNOME
# Note: Display manager should be configured separately (e.g., FTS.desktop._.display-manager._.gdm)
{
  den,
  lib,
  FTS,
  ...
}:
{
  # Base GNOME desktop environment
  # Usage: (<FTS/desktop/environment/gnome> { })
  FTS.desktop._.environment._.gnome = {
    description = "GNOME desktop environment";

    nixos = {
      # Enable GNOME desktop manager
      services.desktopManager.gnome.enable = true;

      # Enable sysprof service for profiling
      services.sysprof.enable = true;

      # Enable sensor support for automatic screen rotation
      hardware.sensor.iio.enable = true;

      # Qt integration for better GNOME look
      qt = {
        enable = true;
        platformTheme = lib.mkDefault "gnome";
        style = lib.mkDefault "adwaita-dark";
      };
      
      # Don't set SSH askPassword (override default from gnome module)
      programs.ssh.askPassword = lib.mkForce "";
    };
  };

  # TODO: Add parametric theme support for GNOME like KDE has
  # FTS.desktop._.environment._.gnome = args: { class, aspect-chain }: { ... };
}
