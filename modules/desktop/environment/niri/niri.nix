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
      Niri scrollable-tiling Wayland compositor (the shell is Loft, fleet.desktop._.loft).

      A Wayland compositor where windows are arranged in an infinite
      horizontal scrollable strip of columns.

      Homepage: https://github.com/niri-wm/niri
      NixOS module: github:sodiboo/niri-flake
      Config format: plain niri KDL in modules/desktop/environment/niri/_config
    '';

    includes = [
      fleet.desktop._.environment._.niri._.xremap
      (fleet.user._.groups [ "input" ])
    ];

    nixos =
      { pkgs, ... }:
      {
        imports = [ inputs.niri-flake.nixosModules.niri ];

        programs.niri.enable = true;
        programs.niri.package = pkgs.niri;

        # XDG portals for screen sharing, file picker, etc.
        #
        # niri implements the GNOME/Mutter ScreenCast D-Bus API (verify with
        # `busctl --user list | grep Mutter.ScreenCast`), so xdg-desktop-portal-gnome
        # is the correct — and niri-recommended — screencast backend: it gives a
        # real monitor+window picker with restore tokens, which is what
        # Discord/equibop need to share screen. xdg-desktop-portal-wlr only does
        # whole-output capture and is unreliable for app screensharing here.
        # gtk handles the file chooser and other interfaces. grim/slurp talk to
        # niri's wlr-screencopy directly, so dropping the wlr *portal* does not
        # affect screenshots.
        xdg.portal = {
          enable = true;
          extraPortals = [
            pkgs.xdg-desktop-portal-gnome
            pkgs.xdg-desktop-portal-gtk
          ];
          config.niri = {
            default = [
              "gnome"
              "gtk"
            ];
            "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
            "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
          };
        };

        security.polkit.enable = true;

        environment.systemPackages = with pkgs; [
          xwayland-satellite # XWayland support for legacy apps
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

    # Per-user half. Host scope never delivers homeManager, so this rides
    # the explicit host→users edge to every user on hosts that include it.
    provides.to-users.includes = [
      {
        homeManager =
          {
            config,
            lib,
            pkgs,
            ...
          }:
          let
            configRoot = "${config.home.homeDirectory}/.flake/modules/desktop/environment/niri/_config";
            # Live-editable links into the ~/.flake checkout only for cody;
            # everyone else (no checkout: carter on electric, the guest
            # accounts) gets the tree from the store, as deployed.
            editable = config.home.username == "cody";
          in
          {
            # Override niri-flake's homeModules.config which sets enable = (finalConfig != null).
            # Since we use a plain KDL tree instead of programs.niri.settings, finalConfig is null
            # and niri-flake disables the xdg config file. Force it back on.
            xdg.configFile."niri".enable = lib.mkForce true;
            xdg.configFile."niri".force = true;
            xdg.configFile."niri".source =
              if editable then config.lib.file.mkOutOfStoreSymlink configRoot else ./_config;

            # Wine/Steam export icons into ~/.local/share/icons/hicolor and write
            # a minimal index.theme (48/128/256 apps only). XDG_DATA_HOME outranks
            # XDG_DATA_DIRS in icon lookup, so that index shadows the real hicolor
            # index for Qt/quickshell — every icon outside those sizes renders as
            # the missing-texture grid in Loft's shell (e.g. zed, 512x512-only). Watch
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
          };
      }
    ];
  };
}
