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
  cfg = config.${namespace}.bundles.shell;
in
{
  options.${namespace}.bundles.shell = with types; {
    enable = mkBoolOpt false "Enable shell bundle";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ yazi ];
    ${namespace} = {
      programs = {
        atuin = enabled;
        eza = enabled;
        fzf = enabled;
        powerlevel10k = enabled ;
        starship = enabled;
        stylix = mkForce enabled; # Force enable for shell features
        zoxide = enabled;
        zsh = enabled;
      };
    };
  };
}
