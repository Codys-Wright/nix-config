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
  cfg = config.${namespace}.gaming.lutris;
in
{
  options.${namespace}.gaming.lutris = with types; {
    enable = mkBoolOpt false "Enable Lutris gaming platform";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      lutris
      equibop
    ];
  };
} 