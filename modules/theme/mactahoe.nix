# MacTahoe Theme Packages
# Installs MacTahoe GTK theme, icon theme, and cursor theme
{
  FTS.mactahoe = {
    description = "MacTahoe theme packages - macOS Tahoe-inspired GTK theming";

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          (pkgs.callPackage ../../packages/mactahoe/gtk-theme.nix {
            withBlur = true;
            colorVariants = [ "dark" ];
            themeVariants = [ "blue" ];
          })
          (pkgs.callPackage ../../packages/mactahoe/icon-theme.nix {
            themeVariants = [ "blue" ];
          })
          (pkgs.callPackage ../../packages/mactahoe/cursor-theme.nix { })
        ];
      };

    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [
          (pkgs.callPackage ../../packages/mactahoe/gtk-theme.nix {
            withBlur = true;
            colorVariants = [ "dark" ];
            themeVariants = [ "blue" ];
          })
          (pkgs.callPackage ../../packages/mactahoe/icon-theme.nix {
            themeVariants = [ "blue" ];
          })
          (pkgs.callPackage ../../packages/mactahoe/cursor-theme.nix { })
        ];
      };
  };
}
