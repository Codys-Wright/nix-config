# MacTahoe KDE Theme
# Full macOS Tahoe-inspired theming for KDE Plasma with Kvantum
{
  fleet,
  inputs,
  pkgs,
  lib,
  ...
}:
{
  fleet.desktop._.environment._.kde._.themes._.whitesur = {
    description = "MacTahoe KDE theme (macOS Tahoe style with Kvantum)";

    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [
          (pkgs.callPackage ../../../../../packages/mactahoe/kde-theme.nix { })
          pkgs.kdePackages.qtstyleplugin-kvantum
        ];
      };

    homeManager =
      {
        pkgs,
        lib,
        config,
        ...
      }:
      {
        home.packages = [
          (pkgs.callPackage ../../../../../packages/mactahoe/kde-theme.nix { })
          pkgs.kdePackages.qtstyleplugin-kvantum
        ];

        gtk = {
          enable = true;
          theme.name = lib.mkForce "MacTahoe-Dark-Blue";
          iconTheme.name = lib.mkForce "MacTahoe-blue";
          cursorTheme = {
            name = lib.mkForce "MacTahoe-dark-cursors";
            size = lib.mkForce 24;
          };
          gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
          gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
        };

        xdg.configFile."kdedefaults/kdeglobals".text = ''
          [General]
          ColorScheme=MacTahoeDark

          [Icons]
          Theme=MacTahoe-blue

          [KDE]
          LookAndFeelPackage=com.github.vinceliuice.MacTahoe-Dark
          widgetStyle=kvantum-dark
        '';

        xdg.configFile."kdedefaults/plasmarc".text = ''
          [Theme]
          name=MacTahoe-Dark
        '';

        xdg.configFile."kdedefaults/kwinrc".text = ''
          [org.kde.kdecoration2]
          library=org.kde.kwin.aurorae
          theme=__aurorae__svg__MacTahoe-Dark
        '';

        home.file.".local/bin/mactahoe-apply" = {
          executable = true;
          text = ''
            #!/bin/sh
            MARKER="$HOME/.local/share/mactahoe-layout-applied"

            if [ ! -f "$MARKER" ]; then
              plasma-apply-lookandfeel --resetLayout --apply com.github.vinceliuice.MacTahoe-Dark
              mkdir -p "$(dirname "$MARKER")"
              touch "$MARKER"
            else
              plasma-apply-lookandfeel --apply com.github.vinceliuice.MacTahoe-Dark
            fi

            plasma-apply-colorscheme MacTahoeDark
            plasma-apply-cursortheme --size 24 MacTahoe-dark-cursors
            plasma-apply-desktoptheme MacTahoe-Dark
            kwriteconfig6 --file kdeglobals --group Icons --key Theme MacTahoe-blue
            dbus-send --session --dest=org.kde.KIconLoader /KIconLoader org.kde.KIconLoader.iconChanged int32:0 2>/dev/null || true
            kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle kvantum-dark

            # Window decorations — Aurorae MacTahoe-Dark
            kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library org.kde.kwin.aurorae
            kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme __aurorae__svg__MacTahoe-Dark
            dbus-send --session --dest=org.kde.KWin /KWin org.kde.KWin.reconfigure 2>/dev/null || true
          '';
        };

        xdg.configFile."autostart/mactahoe-theme-apply.desktop".text = ''
          [Desktop Entry]
          Type=Application
          Name=Apply MacTahoe Theme
          Exec=sh $HOME/.local/bin/mactahoe-apply
          X-KDE-autostart-phase=2
          OnlyShowIn=KDE;
        '';

        home.activation.applyMacTahoeLookAndFeel = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          DBUS_ADDR=""
          for pid in $(pgrep -u "$USER" plasmashell 2>/dev/null); do
            DBUS_ADDR=$(cat /proc/$pid/environ 2>/dev/null | tr '\0' '\n' | grep ^DBUS_SESSION_BUS_ADDRESS= | cut -d= -f2-)
            [ -n "$DBUS_ADDR" ] && break
          done

          if [ -n "$DBUS_ADDR" ]; then
            export DBUS_SESSION_BUS_ADDRESS="$DBUS_ADDR"
            for pid in $(pgrep -u "$USER" plasmashell 2>/dev/null); do
              eval "$(cat /proc/$pid/environ 2>/dev/null | tr '\0' '\n' | grep -E '^(DISPLAY|WAYLAND_DISPLAY)=' | head -2)"
              break
            done
            export DISPLAY WAYLAND_DISPLAY
            $HOME/.local/bin/mactahoe-apply 2>/dev/null || true
          fi
        '';
      };
  };
}
