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
  cfg = config.${namespace}.app.media.freetube;
in
{
  options.${namespace}.app.media.freetube = with types; {
    enable = mkBoolOpt false "Enable FreeTube YouTube client";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      freetube
    ];
  };
}
