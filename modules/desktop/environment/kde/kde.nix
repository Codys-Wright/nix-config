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

        systemd.user.settings.Manager.DefaultTasksMax = 16384;

        # xdg-desktop-portal-kde's wrapper only sets QT_PLUGIN_PATH/XDG_DATA_DIRS,
        # not QML_IMPORT_PATH — its screencast/screenshot picker dialogs (from
        # kpipewire) fail to load ("qmlRegisterType requires absolute URLs") and
        # the portal request silently auto-rejects. Qt6 (kwin, plasma, the KDE
        # portal) reads QML_IMPORT_PATH, not the Qt5-era QML2_IMPORT_PATH.
        # Plasma's session-env mechanism (sourced by startplasma at login, see
        # plasma-workspace/libexec/plasma-sourceenv.sh) picks up
        # /etc/xdg/plasma-workspace/env/*.sh and exports it into the session
        # (and from there into the D-Bus-activated portal's environment).
        environment.etc."xdg/plasma-workspace/env/qml-import-path.sh".text = ''
          export QML_IMPORT_PATH="$NIXPKGS_QT6_QML_IMPORT_PATH:$QML_IMPORT_PATH"
          export QML2_IMPORT_PATH="$NIXPKGS_QT6_QML_IMPORT_PATH:$QML2_IMPORT_PATH"
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
