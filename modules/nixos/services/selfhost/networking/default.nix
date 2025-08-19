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
  cfg = config.${namespace}.services.selfhost.networking;
in
{
  options.${namespace}.services.selfhost.networking = with types; {
    enable = mkBoolOpt false "Enable networking services";
  };
} 