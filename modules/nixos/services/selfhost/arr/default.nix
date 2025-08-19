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
  cfg = config.${namespace}.services.selfhost.arr;
in
{
  options.${namespace}.services.selfhost.arr = with types; {
    enable = mkBoolOpt false "Enable arr services (media management suite)";
  };
} 