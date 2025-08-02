{
  options,
  config,
  lib,
  pkgs,
  namespace,
  inputs,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.programs.code-cursor;
in
{
  options.${namespace}.programs.code-cursor = with types; {
    enable = mkBoolOpt false "Enable code-cursor";
  };
  
  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      code-cursor
    ];
  };
}
