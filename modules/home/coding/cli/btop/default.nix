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
  cfg = config.${namespace}.coding.cli.btop;
in
{
  options.${namespace}.coding.cli.btop = with types; {
    enable = mkBoolOpt false "Enable Btop system monitor";
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
