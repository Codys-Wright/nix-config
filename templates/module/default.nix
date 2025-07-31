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
  cfg = config.${namespace}.module;
in
{
  options.${namespace}.module = with types; {
    enable = mkBoolOpt false "Enable module";
  };

  config = mkIf cfg.enable { };
}