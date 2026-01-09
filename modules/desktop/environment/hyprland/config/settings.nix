# Hyprland general settings, decorations, animations, input
{FTS, ...}: {
  FTS.desktop._.environment._.hyprland._.config._.settings = {
    description = "Hyprland general settings, decorations, animations, and input configuration";

    homeManager = let
      animationDuration = 2.5;
      borderDuration = 1.0;
    in {
      wayland.windowManager.hyprland.settings = {
        # NOTE: Workflow profiles are sourced via './profile.conf' in workflows.nix
        # Settings defined here will OVERRIDE workflow-specific settings.
        # To allow workflows to control a setting, remove it from here and
        # define it in the workflow profile instead.

        # General window management settings
        general = {
          resize_on_border = true;
          gaps_in = 3;
          gaps_out = 5;
          border_size = 1;
          layout = "master";
        };

        # Debug settings
        debug.disable_logs = false;

        # Window decoration (opacity, rounding, shadows, blur)
        decoration = {
          active_opacity = 0.9;
          inactive_opacity = 0.8;
          rounding = 10;
          shadow = {
            enabled = true;
            range = 20;
            render_power = 3;
          };
          blur.enabled = true;
          border_part_of_window = true;
        };

        # Master layout configuration
        master = {
          new_status = "slave";
          allow_small_split = true;
          mfact = 0.5;
        };

        # Miscellaneous settings
        misc = {
          vfr = true;
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
          disable_autoreload = true;
          focus_on_activate = true;
        };

        # Input device configuration
        input = {
          kb_layout = "us";
          kb_variant = "altgr-intl";
          follow_mouse = 1;
          sensitivity = 0.0;
          repeat_delay = 300;
          repeat_rate = 50;

          touchpad = {
            natural_scroll = true;
            tap-to-click = true;
          };
        };

        # # Animations configuration
        # animations = {
        #   enabled = true;
        #
        #   # Bezier curves for animations
        #   bezier = [
        #     "linear, 0, 0, 1, 1"
        #     "md3_standard, 0.2, 0, 0, 1"
        #     "md3_decel, 0.05, 0.7, 0.1, 1"
        #     "md3_accel, 0.3, 0, 0.8, 0.15"
        #     "overshot, 0.05, 0.9, 0.1, 1.1"
        #     "crazyshot, 0.1, 1.5, 0.76, 0.92"
        #     "hyprnostretch, 0.05, 0.9, 0.1, 1.0"
        #     "menu_decel, 0.1, 1, 0, 1"
        #     "menu_accel, 0.38, 0.04, 1, 0.07"
        #     "easeInOutCirc, 0.85, 0, 0.15, 1"
        #     "easeOutCirc, 0, 0.55, 0.45, 1"
        #     "easeOutExpo, 0.16, 1, 0.3, 1"
        #     "softAcDecel, 0.26, 0.26, 0.15, 1"
        #     "md2, 0.4, 0, 0.2, 1"
        #   ];
        #
        #   # Animation definitions
        #   animation = [
        #     "windows, 1, ${toString animationDuration}, md3_decel, popin 60%"
        #     "windowsIn, 1, ${toString animationDuration}, md3_decel, popin 60%"
        #     "windowsOut, 1, ${toString animationDuration}, md3_accel, popin 60%"
        #     "border, 1, ${toString borderDuration}, default"
        #     "fade, 1, ${toString animationDuration}, md3_decel"
        #     "layersIn, 1, ${toString animationDuration}, menu_decel, slide"
        #     "layersOut, 1, ${toString animationDuration}, menu_accel"
        #     "fadeLayersIn, 1, ${toString animationDuration}, menu_decel"
        #     "fadeLayersOut, 1, ${toString animationDuration}, menu_accel"
        #     "workspaces, 1, ${toString animationDuration}, menu_decel, slide"
        #     "specialWorkspace, 1, ${toString animationDuration}, md3_decel, slidevert"
        #   ];
        # };
      };
    };
  };
}
