# GNOME Desktop Environment with MacTahoe theming
{
  lib,
  fleet,
  ...
}:
{
  fleet.desktop._.environment._.gnome = {
    description = "GNOME desktop environment with MacTahoe theme";

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

    # Per-user half. Host scope never delivers homeManager, so this rides
    # the explicit host→users edge to every user on hosts that include it.
    provides.to-users.homeManager =
      { pkgs, lib, ... }:
      {
        # Theme packages are installed by the mactahoe aspect — don't duplicate here.
        gtk = {
          enable = true;
          theme.name = lib.mkForce "MacTahoe-Dark-blue";
          gtk4.theme.name = lib.mkForce "MacTahoe-Dark-blue";
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
            gtk-theme = "MacTahoe-Dark-blue";
            icon-theme = "MacTahoe-blue";
            cursor-theme = "MacTahoe-dark-cursors";
            cursor-size = 24;
          };
        };
      };
  };

}
