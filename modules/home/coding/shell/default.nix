{ config, lib, pkgs, namespace, ... }:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.coding.shell;
in
{
  options.${namespace}.coding.shell = with types; {
    enable = mkBoolOpt false "Enable shell tools";
  };

  config = mkIf cfg.enable {
    # Add shell tools here
  };
} 