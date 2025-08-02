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
  cfg = config.${namespace}.programs.code-cursor;
in
{
  options.${namespace}.programs.code-cursor = with types; {
    enable = mkBoolOpt false "Enable the code-cursor module.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      code-cursor
    ];
  };
}