{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:

with lib; 
with lib.${namespace};
let
  cfg = config.${namespace}.coding.editor.code-cursor;
in
{
  options.${namespace}.coding.editor.code-cursor = with types; {
    enable = mkBoolOpt false "Enable Code Cursor editor";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      code-cursor
    ];
  };
}