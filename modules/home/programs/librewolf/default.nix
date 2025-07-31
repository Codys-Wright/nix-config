{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.programs.librewolf;
in
{
  options.${namespace}.programs.librewolf = {
    enable = mkBoolOpt false "${namespace}.programs.librewolf.enable";
  };

  config = mkIf cfg.enable {
    programs.librewolf = {
      enable = true;
    };
  };
}
