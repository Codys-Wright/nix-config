{
  config,
  pkgs,
  lib,
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
  options.${namespace}.programs.code-cursor = {
    enable = mkBoolOpt false "${namespace}.programs.code-cursor.enable";
  };
   config = mkIf cfg.enable {
    home.packages = with pkgs; [
      code-cursor
    ];
  };
}
