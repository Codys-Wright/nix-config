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
  cfg = config.${namespace}.coding.terminal.tmux;
in
{
  options.${namespace}.coding.terminal.tmux = with types; {
    enable = mkBoolOpt false "Enable tmux terminal multiplexer";
  };

  config = mkIf cfg.enable {
    programs.tmux = {
      enable = true;
      mouse = true;
      shell = "${pkgs.zsh}/bin/zsh";
      prefix = "C-Space";
      terminal = "kitty";
      keyMode = "vi";
      baseIndex = 1;

      extraConfig = ''
        set -g set-clipboard on
        bind r source-file ~/.config/tmux/tmux.conf \; display "Reloaded!"
      '';

      plugins = with pkgs; [
        tmuxPlugins.catppuccin
        tmuxPlugins.vim-tmux-navigator
        tmuxPlugins.resurrect
        tmuxPlugins.sensible
      ];
    };
  };
}
