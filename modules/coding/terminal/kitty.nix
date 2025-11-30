# Kitty terminal emulator aspect
{
  FTS, ... }:
{
  FTS.kitty = {
    description = "Kitty terminal emulator with custom configuration";


    homeManager = { config, pkgs, lib, ... }: {
      programs.kitty = lib.mkDefault {
        enable = true;
        themeFile = "Catppuccin-Mocha";
        shellIntegration = {
          mode = "enabled";
          enableZshIntegration = true;
        };
        settings = {
          confirm_os_window_close = "0";
          cursor_shape = "Underline";
          cursor_underline_thickness = 3;
          disable_ligatures = "never";
          enable_audio_bell = false;
          initial_window_height = 600;
          initial_window_width = 1200;
          remember_window_size = "no";
          scrollback_lines = 10000;
          update_check_interval = 0;
          url_style = "curly";
          window_padding_width = 10;

          # Additional useful settings
          tab_bar_style = "powerline";
          tab_powerline_style = "slanted";
          tab_title_template = "{title}{' :{}:'.format(num_windows) if num_windows > 1 else ''}";

          # Performance optimizations
          sync_to_monitor = true;

          # Better font rendering
          text_composition_strategy = "platform";
        };

        keybindings = {
          # Tab management
          "ctrl+shift+t" = "new_tab";
          "ctrl+shift+w" = "close_tab";
          "ctrl+shift+right" = "next_tab";
          "ctrl+shift+left" = "previous_tab";

          # Window management
          "ctrl+shift+enter" = "new_window";
          "ctrl+shift+n" = "new_os_window";

          # Font size
          "ctrl+shift+equal" = "increase_font_size";
          "ctrl+shift+minus" = "decrease_font_size";
          "ctrl+shift+backspace" = "restore_font_size";

          # Scrollback
          "ctrl+shift+up" = "scroll_line_up";
          "ctrl+shift+down" = "scroll_line_down";
          "ctrl+shift+page_up" = "scroll_page_up";
          "ctrl+shift+page_down" = "scroll_page_down";
          "ctrl+shift+home" = "scroll_home";
          "ctrl+shift+end" = "scroll_end";
        };
      };

      # Additional kitty utilities
      home.packages = with pkgs; [
        kitty-themes
      ];

      # Environment variables
      home.sessionVariables = {
        TERMINAL = "kitty";
        TERM = "xterm-kitty";
      };

      # Shell aliases for kitty
      programs.zsh.shellAliases = {
        "icat" = "kitty +kitten icat";
        "kdiff" = "kitty +kitten diff";
        "kssh" = "kitty +kitten ssh";
      };
    };
  };
}
