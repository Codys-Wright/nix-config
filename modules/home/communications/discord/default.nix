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
  cfg = config.${namespace}.communications.discord;
in
{
  options.${namespace}.communications.discord = with types; {
    enable = mkBoolOpt false "Enable Discord desktop application";
    useEquibop = mkBoolOpt false "Use Equibop instead of Discord (better performance)";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      (if cfg.useEquibop then equibop else discord)
    ];
  };
}
