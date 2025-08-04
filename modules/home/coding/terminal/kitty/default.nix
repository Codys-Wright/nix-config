{
  options,
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.coding.terminal.kitty;
in
{
  options.${namespace}.coding.terminal.kitty = with types; {
    enable = mkBoolOpt false "Enable kitty terminal";
  };

  config = mkIf cfg.enable {
    programs.kitty = {
      enable = true;
      font = {
        name = "MesloLGS NF";
        package = pkgs.meslo-lgs-nf;
      };
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
      };
    };
  };
}
