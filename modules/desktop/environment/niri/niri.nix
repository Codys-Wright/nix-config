# Niri - Scrollable-tiling Wayland compositor
{
  FTS,
  inputs,
  pkgs,
  ...
}: {
  FTS.desktop._.environment._.niri = {
    description = ''
      Niri scrollable-tiling Wayland compositor.

      A Wayland compositor where windows are arranged in an infinite
      horizontal scrollable strip of columns.

      Homepage: https://github.com/niri-wm/niri
      NixOS module: github:sodiboo/niri-flake
    '';

    nixos =
      { pkgs, ... }:
      {
        imports = [ inputs.niri-flake.nixosModules.niri ];

        programs.niri = {
          enable = true;
        };

        # XDG portals for screen sharing, file picker, etc.
        xdg.portal = {
          enable = true;
          extraPortals = [
            pkgs.xdg-desktop-portal-gtk
            pkgs.xdg-desktop-portal-gnome
          ];
          config.common.default = [
            "gnome"
            "gtk"
          ];
        };

        # Polkit agent needed for privilege escalation dialogs
        security.polkit.enable = true;

        environment.systemPackages = with pkgs; [
          xwayland-satellite # XWayland support for legacy apps
          waybar # Status bar
          fuzzel # App launcher
          swww # Wallpaper daemon
          swaylock # Screen locker
          swayidle # Idle management
          mako # Notification daemon
          wl-clipboard # Clipboard utilities
        ];
      };

    homeManager =
      { pkgs, ... }:
      {
        imports = [ inputs.niri-flake.homeModules.niri ];

        programs.niri = {
          enable = true;

          settings = {
            # Keyboard input
            input.keyboard = {
              xkb.layout = "us";
            };

            # Touchpad settings
            input.touchpad = {
              tap = true;
              natural-scroll = true;
            };

            # Layout
            layout = {
              gaps = 8;
              center-focused-column = "never";
              default-column-width.proportion = 0.5;
              border = {
                width = 2;
                active.color = "#89b4fa"; # Catppuccin blue
                inactive.color = "#313244";
              };
            };

            # Animations
            animations.enable = true;

            # Prefer client-side decorations
            prefer-no-csd = true;

            # Environment variables
            environment = {
              DISPLAY = ":0"; # for xwayland-satellite
              NIXOS_OZONE_WL = "1";
              MOZ_ENABLE_WAYLAND = "1";
            };

            # Spawn at startup
            spawn-at-startup = [
              { command = [ "xwayland-satellite" ]; }
              { command = [ "mako" ]; }
              { command = [ "swww-daemon" ]; }
              { command = [ "waybar" ]; }
            ];

            # Key bindings
            binds =
              let
                mod = "Super";
              in
              {
                # Spawn terminal
                "${mod}+Return".action.spawn = "kitty";
                # App launcher
                "${mod}+D".action.spawn = "fuzzel";
                # Close window
                "${mod}+Q".action.close-window = { };
                # Focus movement
                "${mod}+H".action.focus-column-left = { };
                "${mod}+L".action.focus-column-right = { };
                "${mod}+J".action.focus-window-down = { };
                "${mod}+K".action.focus-window-up = { };
                # Move windows
                "${mod}+Shift+H".action.move-column-left = { };
                "${mod}+Shift+L".action.move-column-right = { };
                "${mod}+Shift+J".action.move-window-down = { };
                "${mod}+Shift+K".action.move-window-up = { };
                # Workspaces
                "${mod}+1".action.focus-workspace = 1;
                "${mod}+2".action.focus-workspace = 2;
                "${mod}+3".action.focus-workspace = 3;
                "${mod}+4".action.focus-workspace = 4;
                "${mod}+5".action.focus-workspace = 5;
                "${mod}+Shift+1".action.move-column-to-workspace = 1;
                "${mod}+Shift+2".action.move-column-to-workspace = 2;
                "${mod}+Shift+3".action.move-column-to-workspace = 3;
                "${mod}+Shift+4".action.move-column-to-workspace = 4;
                "${mod}+Shift+5".action.move-column-to-workspace = 5;
                # Fullscreen
                "${mod}+F".action.fullscreen-window = { };
                # Column width
                "${mod}+Minus".action.set-column-width = "-10%";
                "${mod}+Equal".action.set-column-width = "+10%";
                # Screenshot
                "Print".action.screenshot = { };
                "${mod}+Print".action.screenshot-screen = { };
                # Exit
                "${mod}+Shift+E".action.quit = { };
                # Lock screen
                "${mod}+Shift+L".action.spawn = "swaylock";
              };
          };
        };
      };
  };
}
