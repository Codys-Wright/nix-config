{
  options,
  config,
  lib,
  pkgs,
  namespace,
  inputs,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.desktop.hyprland;
  border-size = 1;
  gaps-in = 3;
  gaps-out = 5;
  active-opacity = 0.9;
  inactive-opacity = 0.8;
  rounding = 10;
in
{
  options.${namespace}.desktop.hyprland = with types; {
    enable = mkBoolOpt false "Enable hyprland";
  };

  config = mkIf cfg.enable {
    zeus.desktop.hyprland = {
      animations = enabled;
      keybindings = enabled;
    };
    home.packages = with pkgs; [
      qt5.qtwayland
      qt6.qtwayland
      libsForQt5.qt5ct
      qt6ct
      hyprshot
      hyprpicker
      swappy
      imv
      wf-recorder
      wlr-randr
      wl-clipboard
      brightnessctl
      gnome-themes-extra
      libva
      dconf
      wayland-utils
      wayland-protocols
      direnv
      meson
    ];

    wayland.windowManager.hyprland = {
      enable = true;
      xwayland.enable = true;
      systemd.enable = true;
      #package = inputs.hyprland.packages."${pkgs.system}".hyprland;

      settings = {
        "$mod" = "SUPER";
        "$shiftMod" = "SUPER_SHIFT";

        monitor = [
          ",prefered,auto,auto"
          "Unknown-1, disable"
        ];

        cursor = {
          no_hardware_cursors = true;
        };

        general = {
          resize_on_border = true;
          gaps_in = gaps-in;
          gaps_out = gaps-out;
          border_size = border-size;
          layout = "master";
        };

        debug.disable_logs = false;

        decoration = {
          active_opacity = active-opacity;
          inactive_opacity = inactive-opacity;
          rounding = rounding;
          shadow = {
            enabled = true;
            range = 20;
            render_power = 3;
          };
          blur.enabled = true;
          border_part_of_window = true;
        };

        master = {
          new_status = true;
          allow_small_split = true;
          mfact = 0.5;
        };

        gestures = {
          workspace_swipe = true;
        };

        misc = {
          vfr = true;
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
          disable_autoreload = true;
          focus_on_activate = true;
          new_window_takes_over_fullscreen = 2;
        };

        input = {
          kb_layout = "us";
          kb_variant = "altgr-intl";
          follow_mouse = 1;
          sensitivity = 0.0;
          repeat_delay = 300;
          repeat_rate = 50;

          touchpad = {
            natural_scroll = true;
            #clickfinger_behavior = true;
            tap-to-click = true;
          };
        };

        device = [
          {
            name = "at-translated-set-2-keyboard";
            kb_layout = "ch";
            kb_variant = "";
          }
          {
            name = "logitech-wireless-keyboard-pid:4023";
            kb_layout = "ch";
            kb_variant = "";
          }
          {
            name = "msft0001:00-04f3:3202-mouse";
            sensitivity = 0;
            accel_profile = "adaptive";
          }
        ];

      };
    };

    #systemd.user.targets.hyprland-session.Unit.Wants = [ "xdg-desktop-autostart.target" ];
  };
}
