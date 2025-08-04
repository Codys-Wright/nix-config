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
  cfg = config.${namespace}.coding.shell.powerlevel10k;
in
{
  options.${namespace}.coding.shell.powerlevel10k = {
    enable = mkBoolOpt false "Enable Powerlevel10k shell prompt";
  };

  config = mkIf cfg.enable {
    programs.zsh = {
      initContent = lib.mkOrder 550 ''
        # p10k instant prompt
        P10K_INSTANT_PROMPT="$XDG_CACHE_HOME/p10k-instant-prompt-''${(%):-%n}.zsh"
        [[ ! -r "$P10K_INSTANT_PROMPT" ]] || source "$P10K_INSTANT_PROMPT"
      '';

      plugins = [
        {
          name = "powerlevel10k";
          src = pkgs.zsh-powerlevel10k;
          file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
        }
        {
          file = "p10k.zsh";
          name = "powerlevel10k-config";
          src = ./config;
        }
      ];
    };
  };
}
