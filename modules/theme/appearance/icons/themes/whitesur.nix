# WhiteSur Icon Theme
# macOS Big Sur-like icon theme
{
  FTS,
  pkgs,
  lib,
  ...
}:
{
  FTS.theme._.ions._.themes._.whitesur = {
    description = "WhiteSur icon theme (macOS Big Sur style)";

    homeManager = {
      gtk.iconTheme = {
        name = "WhiteSur";
        package = pkgs.whitesur-icon-theme;
      };
    };
  };

  FTS.theme._.icons._.themes._.whitesur-dark = {
    description = "WhiteSur dark icon theme (macOS Big Sur style)";

    homeManager = {
      gtk.iconTheme = {
        name = "WhiteSur-dark";
        package = pkgs.whitesur-icon-theme;
      };
    };
  };
}
