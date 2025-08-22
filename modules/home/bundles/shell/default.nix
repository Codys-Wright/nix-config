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
      coding = {
        shell = {
          powerlevel10k = enabled;
          starship = enabled;
          zsh = enabled;
        };
      };
    };
  };
}
