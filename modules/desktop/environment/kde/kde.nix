# KDE Plasma Desktop Environment with MacTahoe theming
{
  lib,
  FTS,
  ...
}:
{
  FTS.desktop._.environment._.kde = {
    description = "KDE Plasma 6 desktop environment with MacTahoe theme";

    includes = [ FTS.desktop._.environment._.kde._.themes._.whitesur ];

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
  };
}
