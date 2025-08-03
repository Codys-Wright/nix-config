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
  cfg = config.${namespace}.gaming.steam;
in
{
  options.${namespace}.gaming.steam = with types; {
    enable = mkBoolOpt false "Enable Steam gaming platform";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      steam
    ];
    
    ${namespace} = {
      programs.steam = enabled;
    };
  };
} 