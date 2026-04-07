# KDE Plasma Desktop Environment with MacTahoe theming
{
  lib,
  fleet,
  ...
}:
{
  fleet.desktop._.environment._.kde = {
    description = "KDE Plasma 6 desktop environment with MacTahoe theme";

    includes = [ fleet.desktop._.environment._.kde._.themes._.mactahoe ];

    nixos =
      { pkgs, ... }:
      {
        services.desktopManager.plasma6.enable = true;

        programs.ssh.askPassword = lib.mkForce "";

        programs.xwayland.enable = true;

        environment.systemPackages = with pkgs.kdePackages; [
          dolphin
          konsole
          kate
          ark
          spectacle
          gwenview
          okular
        ];
      };

    homeManager =
      { lib, ... }:
      {
        # Remap app launcher to Super+Space (macOS Spotlight style)
        xdg.configFile."kdedefaults/kglobalshortcutsrc".text = ''
          [krunner.desktop]
          _launch=Meta+Space,Alt+Space,KRunner

          [plasmashell]
          activate application launcher=Meta+Space,Meta+Space,Activate Application Launcher
        '';
      };
  };
}
