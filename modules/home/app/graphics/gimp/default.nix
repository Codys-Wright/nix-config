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
  cfg = config.${namespace}.app.graphics.gimp;
in
{
  options.${namespace}.app.graphics.gimp = with types; {
    enable = mkBoolOpt false "Enable GIMP image editor";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      gimp
    ];
  };
}
