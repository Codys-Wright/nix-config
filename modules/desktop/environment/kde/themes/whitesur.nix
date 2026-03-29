# MacTahoe KDE Theme
# Full macOS Tahoe-inspired theming for KDE Plasma with forceblur and Kvantum
{
  FTS,
  inputs,
  pkgs,
  lib,
  ...
}:
{
  # TODO: re-enable when kwin-effects-forceblur is compatible with current KDE/Qt
  # flake-file.inputs.kwin-effects-forceblur = {
  #   url = "github:taj-ny/kwin-effects-forceblur";
  #   inputs.nixpkgs.follows = "nixpkgs";
  # };

  FTS.desktop._.environment._.kde._.themes._.whitesur = {
    description = "MacTahoe KDE theme (macOS Tahoe style with Kvantum)";

    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [
          (pkgs.callPackage ../../../../../packages/mactahoe/kde-theme.nix {
            colorVariants = [ "dark" ];
          })
          # inputs.kwin-effects-forceblur.packages.${pkgs.system}.default  # broken with current KDE
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
          (pkgs.callPackage ../../../../../packages/mactahoe/kde-theme.nix {
            colorVariants = [ "dark" ];
          })
          # inputs.kwin-effects-forceblur.packages.${pkgs.system}.default  # broken with current KDE
          pkgs.kdePackages.qtstyleplugin-kvantum
        ];

        # GTK theming (for GTK apps running under KDE)
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

        # KDE defaults (merged as fallbacks, don't clobber user config)
        # These go to ~/.config/kdedefaults/ which KDE reads as system defaults
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
          BorderSize=Tiny
          ButtonsOnLeft=XAI
          ButtonsOnRight=
          library=org.kde.kwin.aurorae
          theme=__aurorae__svg__MacTahoe-Dark

          [Windows]
          BorderlessMaximizedWindows=true
        '';

        xdg.configFile."kdedefaults/ksplashrc".text = ''
          [KSplash]
          Engine=KSplashQML
          Theme=com.github.vinceliuice.MacTahoe-Dark
        '';

        xdg.configFile."kdedefaults/kcminputrc".text = ''
          [Mouse]
          cursorTheme=MacTahoe-dark-cursors
          cursorSize=24
        '';

        # Kvantum theme (this one is safe to own fully)
        xdg.configFile."Kvantum/kvantum.kvconfig".text = ''
          [General]
          theme=MacTahoe
        '';

        # Script shared by both autostart and activation
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
          '';
        };

        # Autostart on login
        xdg.configFile."autostart/mactahoe-theme-apply.desktop".text = ''
          [Desktop Entry]
          Type=Application
          Name=Apply MacTahoe Theme
          Exec=sh $HOME/.local/bin/mactahoe-apply
          X-KDE-autostart-phase=2
          OnlyShowIn=KDE;
        '';

        # Also apply on activation (nixos-rebuild switch) if a Plasma session is running
        home.activation.applyMacTahoeLookAndFeel = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          # Find the user's running Plasma session DBus
          DBUS_ADDR=""
          for pid in $(pgrep -u "$USER" plasmashell 2>/dev/null); do
            DBUS_ADDR=$(cat /proc/$pid/environ 2>/dev/null | tr '\0' '\n' | grep ^DBUS_SESSION_BUS_ADDRESS= | cut -d= -f2-)
            [ -n "$DBUS_ADDR" ] && break
          done

          if [ -n "$DBUS_ADDR" ]; then
            export DBUS_SESSION_BUS_ADDRESS="$DBUS_ADDR"
            # Also grab DISPLAY/WAYLAND_DISPLAY from the session
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
