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
  cfg = config.${namespace}.services.selfhost.downloads;
in
{
  options.${namespace}.services.selfhost.downloads = with types; {
    enable = mkBoolOpt false "Enable download services";
  };
} 