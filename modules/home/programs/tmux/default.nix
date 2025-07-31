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
  cfg = config.${namespace}.programs.tmux;
in
{
  options.${namespace}.programs.tmux = with types; {
    enable = mkBoolOpt false "Enable programs.tmux";
  };

  config = mkIf cfg.enable {
    programs.tmux = {
      enable = true;
      mouse = true;
      shell = "${pkgs.zsh}/bin/zsh";
      prefix = "C-s";
      terminal = "kitty";
      keyMode = "vi";
      baseIndex = 1;

      extraConfig = ''
        set -g set-clipboard on
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
