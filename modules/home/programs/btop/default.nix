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
  cfg = config.${namespace}.programs.btop;
in
{
  options.${namespace}.programs.btop = with types; {
    enable = mkBoolOpt false "Enable btop";
  };

  config = mkIf cfg.enable {
    programs.btop = {
      enable = true;
      settings = {
        vim_keys = true;
      };
    };
  };
}
