{ config, lib, pkgs, namespace, storageDriver ? null, ... }:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.coding.tools.docker;
in
{
  options.${namespace}.coding.tools.docker = with types; {
    enable = mkBoolOpt false "Enable Docker tools";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      docker
      docker-compose
      lazydocker
    ];
  };
}
