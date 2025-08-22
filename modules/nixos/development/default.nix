{ config, lib, pkgs, namespace, ... }:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.development;
in
{
  options.${namespace}.development = with types; {
    enable = mkBoolOpt false "Enable development environment";
  };


  config = mkIf cfg.enable {
    ${namespace}.development.docker = enabled;


    environment.systemPackages = with pkgs; [
        zed-editor-fhs
    ];
  };
}
