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

        environment.systemPackages = [
          (pkgs.callPackage ../../../../packages/mactahoe/gtk-theme.nix {
            colorVariants = [ "dark" ];
            themeVariants = [ "blue" ];
          })
          (pkgs.callPackage ../../../../packages/mactahoe/icon-theme.nix {
            themeVariants = [ "blue" ];
          })
          (pkgs.callPackage ../../../../packages/mactahoe/cursor-theme.nix { })
        ];
      };

    homeManager =
      { pkgs, lib, ... }:
      {
        home.packages = [
          (pkgs.callPackage ../../../../packages/mactahoe/gtk-theme.nix {
            colorVariants = [ "dark" ];
            themeVariants = [ "blue" ];
          })
          (pkgs.callPackage ../../../../packages/mactahoe/icon-theme.nix {
            themeVariants = [ "blue" ];
          })
          (pkgs.callPackage ../../../../packages/mactahoe/cursor-theme.nix { })
        ];

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
}
