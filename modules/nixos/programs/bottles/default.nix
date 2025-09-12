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
  cfg = config.${namespace}.programs.bottles;
in
{
  options.${namespace}.programs.bottles = with types; {
    enable = mkBoolOpt false "Enable bottles";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      (bottles.override { removeWarningPopup = true; })
    ];
  };
}
