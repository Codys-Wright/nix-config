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

        # drkonqi-coredump-launcher can crash-loop: when it can't reach a
        # display (or hits a Qt crash) it aborts, that abort is itself a
        # coredump, and drkonqi-coredump-processor launches it again, until
        # the user manager wedges ("manager has too many units"); KDE bugs
        # 517353 / 524048, still seen on 6.7.5. Upstream's socket has
        # TriggerLimitBurst=0 (unlimited). Guard it instead of masking it
        # (masking broke live switches, and every crash then failed the
        # system processor with "Connection refused"):
        #   - only launch with a display in the user manager's environment;
        #   - stop the socket if it fires more than 20 times a minute;
        #   - reap launchers that linger (they hold the 16 socket slots).
        # drkonqi ships these under share/systemd/user, so NixOS doesn't see
        # them as package units: force drop-ins, or these would replace them.
        systemd.user.services."drkonqi-coredump-launcher@" = {
          overrideStrategy = "asDropin";
          unitConfig.ConditionEnvironment = [
            "|WAYLAND_DISPLAY"
            "|DISPLAY"
          ];
          serviceConfig.RuntimeMaxSec = "15min";
        };
        systemd.user.sockets."drkonqi-coredump-launcher" = {
          overrideStrategy = "asDropin";
          socketConfig = {
            TriggerLimitIntervalSec = "60s";
            TriggerLimitBurst = 20;
          };
        };

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

    # Per-user half. Host scope never delivers homeManager, so this rides
    # the explicit host→users edge to every user on hosts that include it.
    provides.to-users.homeManager =
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
