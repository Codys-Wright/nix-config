# Pure niri wrapper settings module — imported by both:
#   - niri-wrapper.nix (sets flake.wrapperModules.niri)
#   - niri.nix nixos block (evaluates wrapper for programs.niri.package)
#   - niri-package.nix (nix run .#niri)
{ config, lib, ... }:
let
  p = config.pkgs;
  noctaliaExe = lib.getExe p.noctalia-shell;
  grim = lib.getExe p.grim;
  slurp = lib.getExe p.slurp;
  swappy = lib.getExe p.swappy;
  wlCopy = "${p.wl-clipboard}/bin/wl-copy";
  wlPaste = "${p.wl-clipboard}/bin/wl-paste";

  # wlr-which-key config embedded in the nix store — no ~/.config file needed
  whichKeyYaml = p.writeText "wlr-which-key.yaml" ''
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
        cmd: "${noctaliaExe} ipc call bluetooth togglePanel"
      - key: "w"
        desc: "WiFi"
        cmd: "${noctaliaExe} ipc call wifi togglePanel"
      - key: "s"
        desc: "Sound"
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
in
{
  config.settings = {
    prefer-no-csd = null;

    input = {
      focus-follows-mouse = null;
      keyboard = {
        xkb = {
          layout = "us";
          options = "caps:escape";
        };
        repeat-rate = 40;
        repeat-delay = 250;
      };
      touchpad = {
        natural-scroll = null;
        tap = null;
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
    };

    environment = {
      DISPLAY = ":0";
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
    };

    # Managed by wrapper — no spawn-at-startup needed
    xwayland-satellite.path = lib.getExe p.xwayland-satellite;

    spawn-at-startup = [ noctaliaExe ];

    binds = {
      # Terminal & launcher
      "Mod+Return".spawn = "kitty";
      "Mod+D".spawn-sh = "${noctaliaExe} ipc call launcher toggle";
      "Mod+Space".spawn = [
        (lib.getExe p.wlr-which-key)
        "${whichKeyYaml}"
      ];

      # Window management
      "Mod+Q".close-window = null;
      "Mod+F".maximize-column = null;
      "Mod+G".fullscreen-window = null;
      "Mod+Shift+F".toggle-window-floating = null;
      "Mod+C".center-column = null;

      # Focus (Vi-keys + arrows)
      "Mod+H".focus-column-left = null;
      "Mod+L".focus-column-right = null;
      "Mod+K".focus-window-up = null;
      "Mod+J".focus-window-down = null;
      "Mod+Left".focus-column-left = null;
      "Mod+Right".focus-column-right = null;
      "Mod+Up".focus-window-up = null;
      "Mod+Down".focus-window-down = null;

      # Move windows
      "Mod+Shift+H".move-column-left = null;
      "Mod+Shift+L".move-column-right = null;
      "Mod+Shift+K".move-window-up = null;
      "Mod+Shift+J".move-window-down = null;

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

      # Mouse wheel navigation
      "Mod+WheelScrollDown".focus-column-right = null;
      "Mod+WheelScrollUp".focus-column-left = null;
      "Mod+Ctrl+WheelScrollDown".focus-workspace-down = null;
      "Mod+Ctrl+WheelScrollUp".focus-workspace-up = null;

      # Volume
      "XF86AudioRaiseVolume".spawn-sh = "wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%+";
      "XF86AudioLowerVolume".spawn-sh = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
      "XF86AudioMute".spawn-sh = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";

      # Screenshots
      "Print".screenshot = null;
      "Mod+Ctrl+S".spawn-sh = "${grim} -l 0 - | ${wlCopy}";
      "Mod+Shift+S".spawn-sh = ''${grim} -g "$(${slurp} -w 0)" - | ${wlCopy}'';
      "Mod+Shift+E".spawn-sh = "${wlPaste} | ${swappy} -f -";

      # Session
      "Mod+Alt+L".spawn = "swaylock";
      "Mod+Shift+Q".quit = null;
    };
  };
}
