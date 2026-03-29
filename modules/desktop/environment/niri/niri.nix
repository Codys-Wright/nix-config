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
      Niri scrollable-tiling Wayland compositor with Noctalia shell.

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

        security.polkit.enable = true;

        environment.systemPackages = with pkgs; [
          xwayland-satellite # XWayland support for legacy apps
          noctalia-shell # Desktop shell (bar + launcher + notifications)
          wlr-which-key # Which-key popup for keybind hints
          swaybg # Wallpaper setter
          swaylock # Screen locker
          swayidle # Idle management
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

        # Noctalia colors — Catppuccin Mocha with blue as primary accent
        xdg.configFile."noctalia/colors.json".text = builtins.toJSON {
          mPrimary = "#89b4fa"; # blue
          mOnPrimary = "#11111b";
          mSecondary = "#cba6f7"; # mauve
          mOnSecondary = "#11111b";
          mTertiary = "#94e2d5"; # teal
          mOnTertiary = "#11111b";
          mError = "#f38ba8"; # red
          mOnError = "#11111b";
          mSurface = "#1e1e2e"; # base
          mOnSurface = "#cdd6f4"; # text
          mSurfaceVariant = "#313244"; # surface1
          mOnSurfaceVariant = "#a3b4eb";
          mOutline = "#4c4f69";
          mShadow = "#11111b";
          mHover = "#89dceb"; # sky
          mOnHover = "#11111b";
        };

        # wlr-which-key menu — Mod+Space shows keybind hints
        xdg.configFile."wlr-which-key/config.yaml".text = ''
          font: "JetBrainsMono Nerd Font 12"
          background: "#1e1e2ed0"
          color: "#cdd6f4"
          border: "#89b4fa"
          separator: " ➜ "
          border_width: 2
          corner_r: 12
          padding: 15
          column_padding: 25
          rows_per_column: 6
          anchor: "bottom-right"
          margin_bottom: 5
          margin_right: 5
          menu:
            - key: "f"
              desc: "Firefox"
              cmd: "firefox"
            - key: "d"
              desc: "Discord"
              cmd: "vesktop"
            - key: "b"
              desc: "Bluetooth"
              cmd: "noctalia-shell ipc call bluetooth togglePanel"
            - key: "w"
              desc: "WiFi"
              cmd: "noctalia-shell ipc call wifi togglePanel"
            - key: "s"
              desc: "Sound (pavucontrol)"
              cmd: "pavucontrol"
            - key: "p"
              desc: "Power"
              submenu:
                - key: "l"
                  desc: "Lock"
                  cmd: "swaylock"
                - key: "r"
                  desc: "Reboot"
                  cmd: "reboot"
                - key: "p"
                  desc: "Poweroff"
                  cmd: "poweroff"
                - key: "e"
                  desc: "Logout (niri)"
                  cmd: "niri msg action quit"
        '';

        programs.niri = {
          enable = true;

          settings = {
            input = {
              keyboard = {
                xkb = {
                  layout = "us";
                  options = "caps:escape";
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

              focus-ring = {
                width = 2;
                active.color = "#89b4fa";
                inactive.color = "#313244";
              };

              border.enable = false;
            };

            animations.enable = true;
            prefer-no-csd = true;

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
              DISPLAY = ":0";
              NIXOS_OZONE_WL = "1";
              MOZ_ENABLE_WAYLAND = "1";
            };

            spawn-at-startup = [
              { command = [ "xwayland-satellite" ]; }
              { command = [ "noctalia-shell" ]; }
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
                # Terminal
                "${mod}+Return".action.spawn = "kitty";

                # Launcher (Noctalia) / which-key
                "${mod}+D".action.spawn-sh = "noctalia-shell ipc call launcher toggle";
                "${mod}+Space".action.spawn = "wlr-which-key";

                # Window management
                "${mod}+Q".action.close-window = { };
                "${mod}+F".action.maximize-column = { };
                "${mod}+G".action.fullscreen-window = { };
                "${mod}+Shift+F".action.toggle-window-floating = { };
                "${mod}+C".action.center-column = { };

                # Focus (Vi + arrows)
                "${mod}+H".action.focus-column-left = { };
                "${mod}+L".action.focus-column-right = { };
                "${mod}+K".action.focus-window-up = { };
                "${mod}+J".action.focus-window-down = { };
                "${mod}+Left".action.focus-column-left = { };
                "${mod}+Right".action.focus-column-right = { };
                "${mod}+Up".action.focus-window-up = { };
                "${mod}+Down".action.focus-window-down = { };

                # Move
                "${mod}+Shift+H".action.move-column-left = { };
                "${mod}+Shift+L".action.move-column-right = { };
                "${mod}+Shift+K".action.move-window-up = { };
                "${mod}+Shift+J".action.move-window-down = { };

                # Resize
                "${mod}+Ctrl+H".action.set-column-width = "-5%";
                "${mod}+Ctrl+L".action.set-column-width = "+5%";
                "${mod}+Ctrl+J".action.set-window-height = "-5%";
                "${mod}+Ctrl+K".action.set-window-height = "+5%";

                # Workspaces (named w0–w9, keyed 1–0)
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

                # Mouse wheel navigation
                "${mod}+WheelScrollDown".action.focus-column-right = { };
                "${mod}+WheelScrollUp".action.focus-column-left = { };
                "${mod}+Ctrl+WheelScrollDown".action.focus-workspace-down = { };
                "${mod}+Ctrl+WheelScrollUp".action.focus-workspace-up = { };

                # Volume
                "XF86AudioRaiseVolume".action.spawn-sh = "${wpctl} set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%+";
                "XF86AudioLowerVolume".action.spawn-sh = "${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 5%-";
                "XF86AudioMute".action.spawn-sh = "${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle";

                # Screenshots
                "Print".action.screenshot = { };
                "${mod}+Ctrl+S".action.spawn-sh = "${grim} -l 0 - | ${wlCopy}";
                "${mod}+Shift+S".action.spawn-sh = "${grim} -g \"$(${slurp} -w 0)\" - | ${wlCopy}";
                "${mod}+Shift+E".action.spawn-sh = "${wlPaste} | ${swappy} -f -";

                # Session
                "${mod}+Alt+L".action.spawn = "swaylock";
                "${mod}+Shift+Q".action.quit = { };
              };
          };
        };
      };
  };
}
