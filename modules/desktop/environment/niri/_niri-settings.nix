# Pure niri wrapper settings module — imported by both:
#   - niri-wrapper.nix (sets flake.wrapperModules.niri)
#   - niri.nix nixos block (evaluates wrapper for programs.niri.package)
#   - niri-package.nix (nix run .#niri)
{ config, lib, ... }:
# v2-settings = true opts into the new action format (_: {} instead of null)
# and silences all deprecation warnings.
let
  p = config.pkgs;
  noctaliaExe = lib.getExe p.noctalia-shell;
  grim = lib.getExe p.grim;
  slurp = lib.getExe p.slurp;
  swappy = lib.getExe p.swappy;
  wlCopy = "${p.wl-clipboard}/bin/wl-copy";
  wlPaste = "${p.wl-clipboard}/bin/wl-paste";

  # Run-or-raise: focus existing window by app-id, or launch if not running
  runOrRaise =
    appId: cmd:
    let
      script = p.writeShellScriptBin "run-or-raise-${appId}" ''
        window_id=$(${p.niri}/bin/niri msg -j windows | ${lib.getExe p.jq} -r '.[] | select(.app_id == "${appId}") | .id' | head -1)
        if [ -n "$window_id" ]; then
          ${p.niri}/bin/niri msg action focus-window --id "$window_id"
        else
          exec ${cmd}
        fi
      '';
    in
    lib.getExe script;

  # Generates a wlr-which-key invocation from a menu list (Nix attrsets → YAML)
  mkWhichKeyExe =
    menu:
    let
      yaml = (p.formats.yaml { }).generate "wlr-which-key.yaml" {
        inherit menu;
        font = "JetBrainsMono Nerd Font 12";
        background = "#1e1e2ed0";
        color = "#cdd6f4";
        border = "#89b4fa";
        separator = " ➜ ";
        border_width = 2;
        corner_r = 12;
        padding = 15;
        column_padding = 25;
        rows_per_column = 6;
        anchor = "bottom-right";
        margin_bottom = 5;
        margin_right = 5;
      };
    in
    "${lib.getExe p.wlr-which-key} ${yaml}";
in
{
  options.spawnShell = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Whether to spawn noctalia-shell on startup. Set false for nested/standalone use.";
  };

  config.v2-settings = true;

  config.settings = {
    # Monitor layout: ultrawide on top, two 1440p below
    outputs = {
      "DP-4" = {
        # MSI MPG491CX OLED ultrawide — top center
        # VRR disabled — causes flickering on this panel
        mode = "5120x1440@240.000";
        position = _: {
          props = {
            x = 0;
            y = 0;
          };
        };
      };
      "DP-5" = {
        # Acer XV271U M3 — bottom left
        mode = "2560x1440@179.999";
        variable-refresh-rate = _: { };
        position = _: {
          props = {
            x = 0;
            y = 1440;
          };
        };
      };
      "HDMI-A-2" = {
        # Acer XV271U M3 — bottom right
        mode = "2560x1440@60.000";
        position = _: {
          props = {
            x = 2560;
            y = 1440;
          };
        };
      };
    };

    prefer-no-csd = _: { };

    input = {
      focus-follows-mouse = _: { };
      keyboard = {
        xkb = {
          layout = "us";
          options = "caps:escape";
        };
        repeat-rate = 40;
        repeat-delay = 250;
      };
      touchpad = {
        natural-scroll = _: { };
        tap = _: { };
      };
      mouse.accel-profile = "flat";
    };

    layout = {
      gaps = 5;
      center-focused-column = "never";
      default-column-width.proportion = 0.5;
      focus-ring = {
        width = 2;
        active-color = "#89b4fa"; # Catppuccin Mocha blue
        inactive-color = "#313244"; # Catppuccin Mocha surface1
      };
    };

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
      music = {
        open-on-output = "DP-4";
      };
      comms = {
        open-on-output = "DP-5";
      };
      media = {
        open-on-output = "DP-5";
      };
      notes = {
        open-on-output = "HDMI-A-2";
      };
      research = {
        open-on-output = "HDMI-A-2";
      };
      gaming = {
        open-on-output = "DP-4";
      };
    };

    # Window rules — use `matches` list (mkRule converts to KDL `match` nodes)
    window-rules = [
      # Main REAPER window → music workspace, maximized on ultrawide
      {
        matches = [
          {
            app-id = "^REAPER$";
            title = "REAPER v";
          }
        ];
        open-on-workspace = "music";
        open-maximized = true;
      }
      # Mixer → music workspace
      {
        matches = [
          {
            app-id = "^REAPER$";
            title = "^Mixer$";
          }
        ];
        open-on-workspace = "music";
      }
      # MIDI editor → music workspace
      {
        matches = [
          {
            app-id = "^REAPER$";
            title = "^MIDI take:";
          }
        ];
        open-on-workspace = "music";
      }
      # Discord (Equibop/Vesktop) → comms workspace
      {
        matches = [
          { app-id = "^equibop$"; }
          { app-id = "^vesktop$"; }
        ];
        open-on-workspace = "comms";
      }
      # Zoom → comms workspace
      {
        matches = [ { app-id = "^zoom$"; } ];
        open-on-workspace = "comms";
      }
      # Slack → comms workspace
      {
        matches = [ { app-id = "^Slack$"; } ];
        open-on-workspace = "comms";
      }
      # Obsidian → notes workspace
      {
        matches = [ { app-id = "^obsidian$"; } ];
        open-on-workspace = "notes";
      }
      # Steam → gaming workspace
      {
        matches = [ { app-id = "^steam$"; } ];
        open-on-workspace = "gaming";
      }
    ];

    environment = {
      DISPLAY = ":0";
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
    };

    # Managed by wrapper — no spawn-at-startup needed
    xwayland-satellite.path = lib.getExe p.xwayland-satellite;

    spawn-at-startup = lib.optionals config.spawnShell [ noctaliaExe ] ++ [
      # Solid Catppuccin Mocha background (no image file needed)
      (lib.getExe (p.writeShellScriptBin "wallpaper" "${lib.getExe p.swaybg} -c '#1e1e2e'"))
    ];

    binds = {
      # Terminal & launcher
      "Mod+Return".spawn = lib.getExe p.kitty;
      "Mod+E".spawn = lib.getExe p.ghostty;
      "Mod+Space".spawn-sh = "${noctaliaExe} ipc call launcher toggle";

      # Which-key popup (Mod=Super on host, Alt when nested)
      "Mod+d".spawn-sh = mkWhichKeyExe [
        {
          key = "b";
          desc = "Browser (LibreWolf)";
          cmd = runOrRaise "librewolf" "librewolf";
        }
        {
          key = "m";
          desc = "Media (Brave)";
          cmd = runOrRaise "brave-browser" "brave";
        }
        {
          key = "z";
          desc = "Zen";
          cmd = runOrRaise "zen" "zen";
        }
        {
          key = "c";
          desc = "Comms";
          cmd = "niri msg action focus-workspace comms";
        }
        {
          key = "v";
          desc = "Discord (Equibop)";
          cmd = runOrRaise "equibop" "equibop";
        }
        {
          key = "a";
          desc = "AI (ChatGPT)";
          cmd = "librewolf --new-window https://chatgpt.com";
        }
        {
          key = "r";
          desc = "Reaper (music)";
          cmd = "niri msg action focus-workspace music";
        }
        {
          key = "n";
          desc = "Notes (Obsidian)";
          cmd = runOrRaise "obsidian" "obsidian";
        }
        {
          key = "e";
          desc = "Research";
          cmd = "niri msg action focus-workspace research";
        }
        {
          key = "g";
          desc = "Gaming";
          cmd = "niri msg action focus-workspace gaming";
        }
        {
          key = "f";
          desc = "Media";
          cmd = "niri msg action focus-workspace media";
        }
        {
          key = "s";
          desc = "Sound";
          cmd = "${lib.getExe p.pavucontrol}";
        }
        {
          key = "t";
          desc = "Bluetooth";
          cmd = "${noctaliaExe} ipc call bluetooth togglePanel";
        }
        {
          key = "w";
          desc = "WiFi";
          cmd = "${noctaliaExe} ipc call wifi togglePanel";
        }
        {
          key = "p";
          desc = "Power";
          submenu = [
            {
              key = "l";
              desc = "Lock";
              cmd = "swaylock";
            }
            {
              key = "r";
              desc = "Reboot";
              cmd = "reboot";
            }
            {
              key = "p";
              desc = "Poweroff";
              cmd = "poweroff";
            }
            {
              key = "e";
              desc = "Logout (niri)";
              cmd = "niri msg action quit";
            }
          ];
        }
      ];

      # Overview
      "Mod+O".toggle-overview = _: { };

      # Window management
      "Mod+Q".close-window = _: { };
      "Mod+F".maximize-column = _: { };
      "Mod+G".fullscreen-window = _: { };
      "Mod+Shift+F".toggle-window-floating = _: { };
      "Mod+C".center-column = _: { };

      # Focus (Vi-keys + arrows) — crosses monitor boundaries
      "Mod+H".focus-column-or-monitor-left = _: { };
      "Mod+L".focus-column-or-monitor-right = _: { };
      "Mod+K".focus-window-or-monitor-up = _: { };
      "Mod+J".focus-window-or-monitor-down = _: { };
      "Mod+Left".focus-column-or-monitor-left = _: { };
      "Mod+Right".focus-column-or-monitor-right = _: { };
      "Mod+Up".focus-window-or-monitor-up = _: { };
      "Mod+Down".focus-window-or-monitor-down = _: { };

      # Move windows — crosses monitor boundaries
      "Mod+Shift+H".move-column-left-or-to-monitor-left = _: { };
      "Mod+Shift+L".move-column-right-or-to-monitor-right = _: { };
      "Mod+Shift+K".move-window-up-or-to-workspace-up = _: { };
      "Mod+Shift+J".move-window-down-or-to-workspace-down = _: { };

      # Resize
      "Mod+Ctrl+H".set-column-width = "-5%";
      "Mod+Ctrl+L".set-column-width = "+5%";
      "Mod+Ctrl+J".set-window-height = "-5%";
      "Mod+Ctrl+K".set-window-height = "+5%";

      # Workspaces (named w0-w9, bound to keys 1-0)
      "Mod+1".focus-workspace = "w0";
      "Mod+2".focus-workspace = "w1";
      "Mod+3".focus-workspace = "w2";
      "Mod+4".focus-workspace = "w3";
      "Mod+5".focus-workspace = "w4";
      "Mod+6".focus-workspace = "w5";
      "Mod+7".focus-workspace = "w6";
      "Mod+8".focus-workspace = "w7";
      "Mod+9".focus-workspace = "w8";
      "Mod+0".focus-workspace = "w9";
      "Mod+Shift+1".move-column-to-workspace = "w0";
      "Mod+Shift+2".move-column-to-workspace = "w1";
      "Mod+Shift+3".move-column-to-workspace = "w2";
      "Mod+Shift+4".move-column-to-workspace = "w3";
      "Mod+Shift+5".move-column-to-workspace = "w4";
      "Mod+Shift+6".move-column-to-workspace = "w5";
      "Mod+Shift+7".move-column-to-workspace = "w6";
      "Mod+Shift+8".move-column-to-workspace = "w7";
      "Mod+Shift+9".move-column-to-workspace = "w8";
      "Mod+Shift+0".move-column-to-workspace = "w9";

      # Workspace navigation (current monitor)
      "Mod+N".focus-workspace-down = _: { };
      "Mod+P".focus-workspace-up = _: { };

      # Mouse wheel navigation
      "Mod+WheelScrollDown".focus-column-right = _: { };
      "Mod+WheelScrollUp".focus-column-left = _: { };
      "Mod+Ctrl+WheelScrollDown".focus-workspace-down = _: { };
      "Mod+Ctrl+WheelScrollUp".focus-workspace-up = _: { };

      # Volume
      "XF86AudioRaiseVolume".spawn-sh = "wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%+";
      "XF86AudioLowerVolume".spawn-sh = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
      "XF86AudioMute".spawn-sh = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";

      # Screenshots
      "Print".screenshot = _: { };
      "Mod+Ctrl+S".spawn = [
        "${lib.getExe p.flameshot}"
        "gui"
        "--clipboard"
      ];
      "Mod+Shift+S".spawn-sh = ''${grim} -g "$(${slurp} -w 0)" - | ${wlCopy}'';
      "Mod+Shift+E".spawn-sh = "${wlPaste} | ${swappy} -f -";

      # Session
      "Mod+Alt+L".spawn = "swaylock";
      "Mod+Shift+Q".quit = _: { };
    };
  };
}
