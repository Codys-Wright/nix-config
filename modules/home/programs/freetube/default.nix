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
  cfg = config.${namespace}.programs.freetube;
in
{
  options.${namespace}.programs.freetube = with types; {
    enable = mkBoolOpt false "Enable freetube";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      freetube
    ];
  };
}
