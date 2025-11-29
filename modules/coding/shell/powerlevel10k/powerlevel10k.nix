# Powerlevel10k shell prompt aspect
{
  FTS, ... }:
{
  FTS.powerlevel10k = {
    description = "Powerlevel10k shell prompt with custom configuration";

    homeManager = { config, pkgs, lib, ... }: {
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

      # Additional packages for powerlevel10k features
      home.packages = with pkgs; [
        # Required for some powerlevel10k features
        zsh-powerlevel10k

        # Recommended fonts (already might be installed by terminal aspects)
        meslo-lgs-nf
      ];
    };
  };
}
