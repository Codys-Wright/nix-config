# Niri - Scrollable-tiling Wayland compositor
# Config lives in _config as plain niri KDL.
# homeManager symlinks ~/.config/niri to that editable tree for live reloads.
{
  fleet,
  den,
  inputs,
  pkgs,
  ...
}:
{
  fleet.desktop._.environment._.niri = {
    description = ''
      Niri scrollable-tiling Wayland compositor with Noctalia shell.

      A Wayland compositor where windows are arranged in an infinite
      horizontal scrollable strip of columns.

      Homepage: https://github.com/niri-wm/niri
      NixOS module: github:sodiboo/niri-flake
      Config format: plain niri KDL in modules/desktop/environment/niri/_config
    '';

    includes = [
      fleet.desktop._.environment._.niri._.xremap
      (den.lib.groups [ "input" ])
    ];

    nixos =
      { pkgs, ... }:
      {
        imports = [ inputs.niri-flake.nixosModules.niri ];

        programs.niri.enable = true;
        programs.niri.package = pkgs.niri;

        # XDG portals for screen sharing, file picker, etc.
        xdg.portal = {
          enable = true;
          extraPortals = [
            pkgs.xdg-desktop-portal-wlr
            pkgs.xdg-desktop-portal-gtk
          ];
          config.niri.default = [
            "wlr"
            "gtk"
          ];
        };

        security.polkit.enable = true;

        environment.systemPackages = with pkgs; [
          xwayland-satellite # XWayland support for legacy apps
          noctalia-shell # Desktop shell (bar + launcher + notifications)
          ghostty # Alternative terminal (Mod+E)
          wlr-which-key # Which-key popup for keybind hints
          swaybg # Wallpaper setter
          swaylock # Screen locker
          swayidle # Idle management
          wl-clipboard # Clipboard utilities
          grim # Screenshot capture
          slurp # Region selection for screenshots
          swappy # Screenshot annotation editor
          nautilus
        ];
      };

    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        configRoot = "${config.home.homeDirectory}/.flake/modules/desktop/environment/niri/_config";
        mutableNoctaliaColors = "${configRoot}/noctalia/colors.json";
      in
      {
        # Override niri-flake's homeModules.config which sets enable = (finalConfig != null).
        # Since we use a plain KDL tree instead of programs.niri.settings, finalConfig is null
        # and niri-flake disables the xdg config file. Force it back on.
        xdg.configFile."niri".enable = lib.mkForce true;
        xdg.configFile."niri".force = true;
        xdg.configFile."niri".source = config.lib.file.mkOutOfStoreSymlink configRoot;

        # Noctalia colors are editable live so the shell can update themes in place.
        xdg.configFile."noctalia/colors.json".source =
          config.lib.file.mkOutOfStoreSymlink mutableNoctaliaColors;

        home.activation.configureNoctaliaWallpaper = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          settings="$HOME/.config/noctalia/settings.json"
          if [ -f "$settings" ]; then
            tmp="$(${pkgs.coreutils}/bin/mktemp -t noctalia-settings.XXXXXX)"
            ${lib.getExe pkgs.jq} '
              .wallpaper.enabled = true
              | .wallpaper.overviewEnabled = true
              | .wallpaper.skipStartupTransition = true
              | .wallpaper.transitionDuration = 0
              | .noctaliaPerformance.disableWallpaper = false
            ' "$settings" > "$tmp"
            install -m 0644 "$tmp" "$settings"
            rm -f "$tmp"
          fi
        '';

        # Wine/Steam export icons into ~/.local/share/icons/hicolor and write
        # a minimal index.theme (48/128/256 apps only). XDG_DATA_HOME outranks
        # XDG_DATA_DIRS in icon lookup, so that index shadows the real hicolor
        # index for Qt/quickshell — every icon outside those sizes renders as
        # the missing-texture grid in noctalia (e.g. zed, 512x512-only). Watch
        # for the file and delete it the moment anything recreates it.
        systemd.user.paths.fix-hicolor-index = {
          Unit.Description = "Watch for Wine's bogus hicolor index.theme";
          Path = {
            PathExists = "%h/.local/share/icons/hicolor/index.theme";
            Unit = "fix-hicolor-index.service";
          };
          Install.WantedBy = [ "default.target" ];
        };

        systemd.user.services.fix-hicolor-index = {
          Unit.Description = "Remove Wine's bogus hicolor index.theme (shadows real icon index)";
          Service = {
            Type = "oneshot";
            ExecStart = "${pkgs.coreutils}/bin/rm -f %h/.local/share/icons/hicolor/index.theme %h/.local/share/icons/hicolor/.icon-theme.cache";
          };
        };

        systemd.user.services.niri-workspace-wallpaper = lib.mkIf (config.home.username == "cody") {
          Unit = {
            Description = "Switch niri wallpaper from the active workspace";
            After = [ "graphical-session.target" ];
            PartOf = [ "graphical-session.target" ];
          };

          Service = {
            ExecStart = "${config.home.homeDirectory}/.config/niri/bin/niri-workspace-wallpaper";
            Restart = "always";
            RestartSec = 2;
            Environment = [
              "PATH=${
                lib.makeBinPath [
                  pkgs.bash
                  pkgs.coreutils
                  pkgs.findutils
                  pkgs.jq
                  pkgs.niri
                  pkgs.noctalia-shell
                  pkgs.procps
                ]
              }"
            ];
          };

          Install.WantedBy = [ "graphical-session.target" ];
        };
      };
  };

  # HM-only aspect for host→user forwarding via provides.to-users.
  # Separates the homeManager config from the nixos block so the niri-flake
  # NixOS module isn't imported twice.
  fleet.desktop._.environment._.niri._.home = {
    description = "Niri home-manager configuration (config.kdl, noctalia colors)";
    homeManager = fleet.desktop._.environment._.niri.homeManager;
  };
}
