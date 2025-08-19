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
  cfg = config.${namespace}.services.selfhost.cloud;
in
{
  options.${namespace}.services.selfhost.cloud = with types; {
    enable = mkBoolOpt false "Enable cloud services";
  };
} 