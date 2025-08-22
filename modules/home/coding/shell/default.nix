{ config, lib, pkgs, namespace, ... }:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.coding.shell;
in
{
  options.${namespace}.coding.shell = with types; {
    enable = mkBoolOpt false "Enable shell tools";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ yazi ];
    
    ${namespace}.coding.shell = {
      powerlevel10k = enabled;
      starship = enabled;
      zsh = enabled;
    };
  };
} 