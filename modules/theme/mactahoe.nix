# MacTahoe Theme Packages
# Installs MacTahoe GTK theme, icon theme, cursor theme, and sets up full theming.
# Note: cursor/icon/GTK theming is handled by stylix — this module adds packages
# and configures what stylix doesn't cover (gtk4, Nautilus, etc.)
{
  fleet.mactahoe = {
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

        # GTK4 settings.ini is managed by stylix's home-manager.gtk integration
        # (uses gtk-icon-theme-name=MacTahoe-blue). A second xdg.configFile.text
        # block here caused HM to concatenate two [Settings] sections; the second
        # named a non-existent bare "MacTahoe" theme, so GTK-4 apps (Files, Zed,
        # qpwgraph, niri launcher) fell back to hicolor and showed pink/black
        # missing-icon placeholders. Trust stylix; do not double-write.

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
