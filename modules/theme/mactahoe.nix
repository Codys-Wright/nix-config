# MacTahoe Theme Packages
# Installs MacTahoe GTK theme, icon theme, cursor theme, and required GNOME extensions
{
  FTS.mactahoe = {
    description = "MacTahoe theme packages - macOS Tahoe-inspired theming with GNOME extensions";

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          # MacTahoe theme packages with blur support, dark and blue variants
          (pkgs.callPackage ../../packages/mactahoe/gtk-theme.nix {
            withBlur = true; # Enable blur version (requires blur-my-shell extension)
            colorVariants = [ "dark" ];
            themeVariants = [ "blue" ];
          })
          (pkgs.callPackage ../../packages/mactahoe/icon-theme.nix {
            themeVariants = [ "blue" ];
          })
          (pkgs.callPackage ../../packages/mactahoe/cursor-theme.nix { })

          # Required GNOME Shell extensions
          pkgs.gnomeExtensions.user-themes
          pkgs.gnomeExtensions.dash-to-dock
          pkgs.gnomeExtensions.blur-my-shell
        ];

        # Enable GNOME Shell extensions via dconf
        dconf.settings = {
          "org/gnome/shell" = {
            enabled-extensions = [
              "user-theme@gnome-shell-extensions.gcampax.github.com"
              "dash-to-dock@micxgx.gmail.com"
              "blur-my-shell@aunetx"
            ];
          };
        };
      };

    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [
          # MacTahoe theme packages with dark and blue variants
          (pkgs.callPackage ../../packages/mactahoe/gtk-theme.nix {
            withBlur = true;
            colorVariants = [ "dark" ];
            themeVariants = [ "blue" ];
          })
          (pkgs.callPackage ../../packages/mactahoe/icon-theme.nix {
            themeVariants = [ "blue" ];
          })
          (pkgs.callPackage ../../packages/mactahoe/cursor-theme.nix { })

          # GNOME extensions and tweaks
          pkgs.gnomeExtensions.user-themes
          pkgs.gnomeExtensions.dash-to-dock
          pkgs.gnomeExtensions.blur-my-shell
          pkgs.gnome-tweaks
        ];
      };
  };
}
