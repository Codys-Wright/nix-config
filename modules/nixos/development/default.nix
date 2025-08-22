{ config, lib, pkgs, namespace, ... }:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.development;
in
{
  options.${namespace}.development = with types; {
    enable = mkBoolOpt false "Enable development environment";
    docker = mkBoolOpt false "Enable Docker development tools";
  };

  config = mkIf cfg.enable {
    imports = mkIf cfg.docker [ ./docker ];
  };
}
