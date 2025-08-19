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
  cfg = config.${namespace}.services.selfhost.backup;
in
{
  options.${namespace}.services.selfhost.backup = with types; {
    enable = mkBoolOpt false "Enable backup services";
  };

  config = mkIf cfg.enable {
    ${namespace}.services.selfhost.backup = {
      restic.enable = mkDefault true;
    };
  };
} 