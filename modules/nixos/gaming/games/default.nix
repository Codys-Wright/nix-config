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
  cfg = config.${namespace}.gaming.games;
in
{
  options.${namespace}.gaming.games = with types; {
    enable = mkBoolOpt false "Enable gaming modules";

  };

  config = mkIf cfg.enable {
  

    ${namespace} = {
    
    };
  };
}
