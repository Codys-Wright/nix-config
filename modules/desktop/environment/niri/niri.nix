# Niri - Scrollable-tiling Wayland compositor
{
  FTS,
  inputs,
  pkgs,
  ...
}:
{
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
          swaybg # Wallpaper setter
          swaylock # Screen locker
          swayidle # Idle management
          mako # Notification daemon
          wl-clipboard # Clipboard utilities
          grim # Screenshot capture
          slurp # Region selection for screenshots
          swappy # Screenshot annotation editor
        ];
      };

    homeManager =
      { pkgs, ... }:
      {
        imports = [ inputs.niri-flake.homeModules.niri ];

        programs.niri = {
          enable = true;

          settings = {
            input = {
              keyboard = {
                xkb = {
                  layout = "us";
                  options = "caps:escape"; # Caps Lock acts as Escape
                };
                repeat-rate = 40;
                repeat-delay = 250;
              };

              touchpad = {
                tap = true;
                natural-scroll = true;
              };

              mouse.accel-profile = "flat";
            };

            layout = {
              gaps = 5;
              center-focused-column = "never";
              default-column-width.proportion = 0.5;

              # Focus ring (active window highlight) — no border on inactive windows
              focus-ring = {
                width = 2;
                active.color = "#89b4fa"; # Catppuccin blue
                inactive.color = "#313244";
              };

              border.enable = false;
            };

            animations.enable = true;
            prefer-no-csd = true;

            # Named workspaces (w0–w9)
            workspaces = {
              w0 = { };
              w1 = { };
              w2 = { };
              w3 = { };
              w4 = { };
              w5 = { };
              w6 = { };
              w7 = { };
              w8 = { };
              w9 = { };
            };

            environment = {
              DISPLAY = ":0"; # for xwayland-satellite
              NIXOS_OZONE_WL = "1";
              MOZ_ENABLE_WAYLAND = "1";
            };

            spawn-at-startup = [
              { command = [ "xwayland-satellite" ]; }
              { command = [ "mako" ]; }
              { command = [ "waybar" ]; }
            ];

            binds =
              let
                mod = "Super";
                grim = "${pkgs.grim}/bin/grim";
                slurp = "${pkgs.slurp}/bin/slurp";
                swappy = "${pkgs.swappy}/bin/swappy";
                wlCopy = "${pkgs.wl-clipboard}/bin/wl-copy";
                wlPaste = "${pkgs.wl-clipboard}/bin/wl-paste";
                wpctl = "wpctl";
              in
              {
                # Terminal / launcher
                "${mod}+Return".action.spawn = "kitty";
                "${mod}+D".action.spawn = "fuzzel";

                # Window management
                "${mod}+Q".action.close-window = { };
                "${mod}+F".action.maximize-column = { };
                "${mod}+G".action.fullscreen-window = { };
                "${mod}+Shift+F".action.toggle-window-floating = { };
                "${mod}+C".action.center-column = { };

                # Focus movement (Vi keys + arrows)
                "${mod}+H".action.focus-column-left = { };
                "${mod}+L".action.focus-column-right = { };
                "${mod}+K".action.focus-window-up = { };
                "${mod}+J".action.focus-window-down = { };
                "${mod}+Left".action.focus-column-left = { };
                "${mod}+Right".action.focus-column-right = { };
                "${mod}+Up".action.focus-window-up = { };
                "${mod}+Down".action.focus-window-down = { };

                # Move windows
                "${mod}+Shift+H".action.move-column-left = { };
                "${mod}+Shift+L".action.move-column-right = { };
                "${mod}+Shift+K".action.move-window-up = { };
                "${mod}+Shift+J".action.move-window-down = { };

                # Resize columns/windows
                "${mod}+Ctrl+H".action.set-column-width = "-5%";
                "${mod}+Ctrl+L".action.set-column-width = "+5%";
                "${mod}+Ctrl+J".action.set-window-height = "-5%";
                "${mod}+Ctrl+K".action.set-window-height = "+5%";

                # Workspaces (named w0–w9)
                "${mod}+1".action.focus-workspace = "w0";
                "${mod}+2".action.focus-workspace = "w1";
                "${mod}+3".action.focus-workspace = "w2";
                "${mod}+4".action.focus-workspace = "w3";
                "${mod}+5".action.focus-workspace = "w4";
                "${mod}+6".action.focus-workspace = "w5";
                "${mod}+7".action.focus-workspace = "w6";
                "${mod}+8".action.focus-workspace = "w7";
                "${mod}+9".action.focus-workspace = "w8";
                "${mod}+0".action.focus-workspace = "w9";
                "${mod}+Shift+1".action.move-column-to-workspace = "w0";
                "${mod}+Shift+2".action.move-column-to-workspace = "w1";
                "${mod}+Shift+3".action.move-column-to-workspace = "w2";
                "${mod}+Shift+4".action.move-column-to-workspace = "w3";
                "${mod}+Shift+5".action.move-column-to-workspace = "w4";
                "${mod}+Shift+6".action.move-column-to-workspace = "w5";
                "${mod}+Shift+7".action.move-column-to-workspace = "w6";
                "${mod}+Shift+8".action.move-column-to-workspace = "w7";
                "${mod}+Shift+9".action.move-column-to-workspace = "w8";
                "${mod}+Shift+0".action.move-column-to-workspace = "w9";

                # Mouse wheel: scroll through columns / workspaces
                "${mod}+WheelScrollDown".action.focus-column-right = { };
                "${mod}+WheelScrollUp".action.focus-column-left = { };
                "${mod}+Ctrl+WheelScrollDown".action.focus-workspace-down = { };
                "${mod}+Ctrl+WheelScrollUp".action.focus-workspace-up = { };

                # Volume (pipewire / wpctl)
                "XF86AudioRaiseVolume".action.spawn-sh = "${wpctl} set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%+";
                "XF86AudioLowerVolume".action.spawn-sh = "${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 5%-";
                "XF86AudioMute".action.spawn-sh = "${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle";

                # Screenshots
                "Print".action.screenshot = { }; # niri built-in interactive screenshot
                "${mod}+Ctrl+S".action.spawn-sh = "${grim} -l 0 - | ${wlCopy}"; # full screen → clipboard
                "${mod}+Shift+S".action.spawn-sh = "${grim} -g \"$(${slurp} -w 0)\" - | ${wlCopy}"; # region → clipboard
                "${mod}+Shift+E".action.spawn-sh = "${wlPaste} | ${swappy} -f -"; # clipboard → swappy editor

                # Session
                "${mod}+Alt+L".action.spawn = "swaylock";
                "${mod}+Shift+Q".action.quit = { };
              };
          };
        };
      };
  };
}
