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
  cfg = config.${namespace}.coding.cli.yazi;
in
{
  options.${namespace}.coding.cli.yazi = with types; {
    enable = mkBoolOpt false "Enable Yazi file manager";
  };

  config = mkIf cfg.enable {
    programs.yazi = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
      shellWrapperName = "y";
    };
  };
}
