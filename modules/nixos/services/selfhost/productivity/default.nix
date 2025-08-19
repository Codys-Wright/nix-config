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
  cfg = config.${namespace}.services.selfhost.productivity;
in
{
  options.${namespace}.services.selfhost.productivity = with types; {
    enable = mkBoolOpt false "Enable productivity services";
  };
} 