{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.programs.zed-editor;
in
{
  options.${namespace}.programs.zed-editor = {
    enable = mkBoolOpt false "${namespace}.programs.zed-editor.enable";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      zed-editor
    ];

    # Configure zed-editor settings
    xdg.configFile = {
      "zed/settings.json" = {
        text = builtins.toJSON {
          # Basic settings
          theme = "dark";
          font_size = 14;
          font_family = "JetBrains Mono";
          
          # Editor settings
          tab_size = 2;
          insert_spaces = true;
          word_wrap = true;
          line_numbers = true;
          
          # File settings
          auto_save = true;
          format_on_save = true;
          
          # Terminal settings
          terminal_font_size = 12;
          
          # Extensions
          extensions = {
            # Add any extensions you want to enable
          };
        };
      };
    };
  };
} 