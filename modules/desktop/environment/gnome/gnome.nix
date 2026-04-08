# GNOME Desktop Environment with MacTahoe theming
{
  lib,
  fleet,
  ...
}:
{
  fleet.desktop._.environment._.gnome = {
    description = "GNOME desktop environment with MacTahoe theme";

    includes = [ fleet.desktop._.environment._.gnome._.nautilus-default ];

    nixos =
      { pkgs, ... }:
      {
        services.desktopManager.gnome.enable = true;

        services.displayManager.defaultSession = lib.mkDefault "gnome";

        services.sysprof.enable = true;

        hardware.sensor.iio.enable = true;

        programs.ssh.askPassword = lib.mkForce "";

        # Theme packages are installed by the mactahoe aspect — don't duplicate here.
      };

    homeManager =
      { pkgs, lib, ... }:
      {
        # Theme packages are installed by the mactahoe aspect — don't duplicate here.
        gtk = {
          enable = true;
          theme.name = lib.mkForce "MacTahoe-Dark-Blue";
          iconTheme.name = lib.mkForce "MacTahoe-blue";
          cursorTheme = {
            name = lib.mkForce "MacTahoe-dark-cursors";
            size = lib.mkForce 24;
          };
          gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
          gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
        };

        dconf.settings = {
          "org/gnome/desktop/interface" = {
            color-scheme = "prefer-dark";
            gtk-theme = "MacTahoe-Dark-Blue";
            icon-theme = "MacTahoe-blue";
            cursor-theme = "MacTahoe-dark-cursors";
            cursor-size = 24;
          };
        };
      };
  };

  # HM-only aspect for host→user forwarding via provides.to-users.
  fleet.desktop._.environment._.gnome._.home = {
    description = "GNOME home-manager configuration (GTK theming, dconf)";
    homeManager = fleet.desktop._.environment._.gnome.homeManager;
  };
}
