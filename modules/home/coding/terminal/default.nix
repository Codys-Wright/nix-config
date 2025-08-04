{ config, lib, pkgs, namespace, ... }:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.coding.terminal;
in
{
  options.${namespace}.coding.terminal = with types; {
    enable = mkBoolOpt false "Enable terminal tools";
  };

  config = mkIf cfg.enable {
    # Add terminal tools here
  };
} 