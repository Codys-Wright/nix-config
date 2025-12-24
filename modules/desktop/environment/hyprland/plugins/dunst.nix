# Dunst - Lightweight notification daemon
{FTS, pkgs, ...}: {
  FTS.desktop._.environment._.hyprland._.plugins._.dunst = {
    description = "Dunst notification daemon for Hyprland";

    homeManager = {pkgs, ...}: {
      # Install dunst
      home.packages = with pkgs; [
        dunst
        libnotify # For notify-send command
      ];

      # Configure dunst
      services.dunst = {
        enable = true;
        
        settings = {
          global = {
            # Display
            monitor = 0;
            follow = "mouse";
            
            # Geometry
            width = 300;
            height = 300;
            origin = "top-right";
            offset = "10x50";
            
            # Progress bar
            progress_bar = true;
            progress_bar_height = 10;
            progress_bar_frame_width = 1;
            progress_bar_min_width = 150;
            progress_bar_max_width = 300;
            
            # Style
            padding = 8;
            horizontal_padding = 8;
            frame_width = 2;
            gap_size = 5;
            separator_height = 2;
            
            # Text
            font = "JetBrainsMono Nerd Font 10";
            line_height = 0;
            markup = "full";
            format = "<b>%s</b>\\n%b";
            alignment = "left";
            vertical_alignment = "center";
            show_age_threshold = 60;
            word_wrap = true;
            ellipsize = "middle";
            ignore_newline = false;
            stack_duplicates = true;
            hide_duplicate_count = false;
            show_indicators = true;
            
            # Icons
            icon_position = "left";
            min_icon_size = 32;
            max_icon_size = 64;
            
            # History
            sticky_history = true;
            history_length = 20;
            
            # Misc
            dmenu = "${pkgs.wofi}/bin/wofi -d";
            browser = "${pkgs.xdg-utils}/bin/xdg-open";
            always_run_script = true;
            title = "Dunst";
            class = "Dunst";
            corner_radius = 10;
            ignore_dbusclose = false;
            force_xwayland = false;
            
            # Mouse
            mouse_left_click = "do_action, close_current";
            mouse_middle_click = "close_current";
            mouse_right_click = "close_all";
          };
          
          urgency_low = {
            background = "#1e1e2e";
            foreground = "#cdd6f4";
            frame_color = "#89b4fa";
            timeout = 5;
          };
          
          urgency_normal = {
            background = "#1e1e2e";
            foreground = "#cdd6f4";
            frame_color = "#89b4fa";
            timeout = 10;
          };
          
          urgency_critical = {
            background = "#1e1e2e";
            foreground = "#cdd6f4";
            frame_color = "#f38ba8";
            timeout = 0;
          };
        };
      };
    };
  };
}
