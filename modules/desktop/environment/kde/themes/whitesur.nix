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
  flake-file.inputs.kwin-effects-forceblur = {
    url = "github:taj-ny/kwin-effects-forceblur";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  FTS.desktop._.environment._.kde._.themes._.whitesur = {
    description = "MacTahoe KDE theme (macOS Tahoe style with forceblur)";

    nixos = { pkgs, ... }: {
      environment.systemPackages = [
        (pkgs.callPackage ../../../../../packages/mactahoe/kde-theme.nix {
          colorVariants = [ "dark" ];
        })
        inputs.kwin-effects-forceblur.packages.${pkgs.system}.default
        pkgs.kdePackages.qtstyleplugin-kvantum
      ];
    };

    homeManager = { pkgs, lib, config, ... }: {
      home.packages = [
        (pkgs.callPackage ../../../../../packages/mactahoe/kde-theme.nix {
          colorVariants = [ "dark" ];
        })
        inputs.kwin-effects-forceblur.packages.${pkgs.system}.default
        pkgs.kdePackages.qtstyleplugin-kvantum
      ];

      # GTK theming (for GTK apps running under KDE)
      gtk = {
        enable = true;
        theme.name = lib.mkForce "MacTahoe-Dark-Blue";
        iconTheme.name = lib.mkForce "MacTahoe-Blue";
        cursorTheme = {
          name = lib.mkForce "MacTahoe-dark-cursors";
          size = lib.mkForce 24;
        };
        gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
        gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
      };

      # Force overwrite gtkrc-2.0 to prevent backup clobbering on switch
      home.file.".gtkrc-2.0".force = true;

      # KDE defaults (merged as fallbacks, don't clobber user config)
      # These go to ~/.config/kdedefaults/ which KDE reads as system defaults
      xdg.configFile."kdedefaults/kdeglobals".text = ''
        [General]
        ColorScheme=MacTahoeDark

        [Icons]
        Theme=MacTahoe-Blue

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

        [Effect-forceblur]
        BlurMatching=true
        BlurExcept=false

        [Plugins]
        forceblurEnabled=true

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

      # Apply look-and-feel on activation
      home.activation.applyMacTahoeLookAndFeel =
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          if command -v plasma-apply-lookandfeel &>/dev/null && [ -n "''${DISPLAY:-}''${WAYLAND_DISPLAY:-}" ]; then
            MARKER="$HOME/.local/share/mactahoe-layout-applied"
            if [ ! -f "$MARKER" ]; then
              # First time: apply with layout reset (sets up top panel + bottom dock)
              plasma-apply-lookandfeel --resetLayout --apply com.github.vinceliuice.MacTahoe-Dark 2>/dev/null || true
              mkdir -p "$(dirname "$MARKER")"
              touch "$MARKER"
            else
              # Subsequent runs: apply theme settings only, preserve panel layout
              plasma-apply-lookandfeel --apply com.github.vinceliuice.MacTahoe-Dark 2>/dev/null || true
            fi
          fi
        '';
    };
  };
}
