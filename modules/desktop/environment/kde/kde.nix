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

        # drkonqi-coredump-launcher SEGV-loops on some crashes and floods
        # the user systemd manager with transient units until the bus wedges
        # ("Cannot add name, manager has too many units"). Mask the launcher;
        # Plasma's on-demand crash dialog (drkonqi proper, via dbus) still works.
        systemd.user.services."drkonqi-coredump-launcher@".enable = false;
        systemd.user.sockets."drkonqi-coredump-launcher".enable = false;

        systemd.user.extraConfig = ''
          DefaultTasksMax=16384
        '';
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

  # HM-only aspect for host→user forwarding via provides.to-users.
  fleet.desktop._.environment._.kde._.home = {
    description = "KDE home-manager configuration (shortcuts, theme defaults)";
    homeManager = fleet.desktop._.environment._.kde.homeManager;
  };
}
