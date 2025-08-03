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
  cfg = config.${namespace}.gaming;
in
{
  options.${namespace}.gaming = with types; {
    enable = mkBoolOpt false "Enable gaming modules";
  };

  config = mkIf cfg.enable {
    ${namespace} = {
      gaming.lutris = mkDefault { enable = true; };
      gaming.steam = mkDefault { enable = true; };
    };
  };
}
