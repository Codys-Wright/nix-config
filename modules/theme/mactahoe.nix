# MacTahoe Theme Packages
# Installs MacTahoe GTK theme, icon theme, cursor theme, and sets up full theming.
# Note: cursor/icon/GTK theming is handled by stylix — this module adds packages
# and configures what stylix doesn't cover (gtk4, Nautilus, etc.)
{
  FTS.mactahoe = {
    description = "MacTahoe theme packages - macOS Tahoe-inspired theming for GTK/niri";

    homeManager =
      { pkgs, ... }:
      let
        gtkTheme = pkgs.callPackage ../../packages/mactahoe/gtk-theme.nix {
          withBlur = true;
          colorVariants = [ "dark" ];
          themeVariants = [ "blue" ];
        };
        iconTheme = pkgs.callPackage ../../packages/mactahoe/icon-theme.nix {
          themeVariants = [ "blue" ];
        };
        cursorTheme = pkgs.callPackage ../../packages/mactahoe/cursor-theme.nix { };
      in
      {
        home.packages = [
          gtkTheme
          iconTheme
          cursorTheme
          pkgs.nautilus
        ];

        # GTK4 apps (including Nautilus) read from gtk-4.0/settings.ini —
        # stylix sets GTK3 but not always GTK4 directly.
        xdg.configFile."gtk-4.0/settings.ini".text = ''
          [Settings]
          gtk-theme-name=MacTahoe-Dark-Blue
          gtk-icon-theme-name=MacTahoe
          gtk-cursor-theme-name=MacTahoe-dark-cursors
          gtk-cursor-theme-size=24
        '';

        # Nautilus as default file manager
        xdg.mimeApps = {
          enable = true;
          defaultApplications = {
            "inode/directory" = "org.gnome.Nautilus.desktop";
            "application/x-gnome-saved-search" = "org.gnome.Nautilus.desktop";
          };
        };
      };

    nixos =
      { pkgs, ... }:
      let
        gtkTheme = pkgs.callPackage ../../packages/mactahoe/gtk-theme.nix {
          withBlur = true;
          colorVariants = [ "dark" ];
          themeVariants = [ "blue" ];
        };
        iconTheme = pkgs.callPackage ../../packages/mactahoe/icon-theme.nix {
          themeVariants = [ "blue" ];
        };
        cursorTheme = pkgs.callPackage ../../packages/mactahoe/cursor-theme.nix { };
      in
      {
        environment.systemPackages = [
          gtkTheme
          iconTheme
          cursorTheme
          pkgs.nautilus
          pkgs.gnome-autoar # archive support for Nautilus
        ];

        # Enable Nautilus GLib/portal integration
        services.gnome.sushi.enable = true;
      };
  };
}
