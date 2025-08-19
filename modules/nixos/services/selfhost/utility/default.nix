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
  cfg = config.${namespace}.services.selfhost.utility;
in
{
  options.${namespace}.services.selfhost.utility = with types; {
    enable = mkBoolOpt false "Enable utility services";
  };
} 