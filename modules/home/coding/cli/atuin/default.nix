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
  cfg = config.${namespace}.coding.cli.atuin;
in
{
  options.${namespace}.coding.cli.atuin = with types; {
    enable = mkBoolOpt false "Enable atuin shell history";
  };

  config = mkIf cfg.enable {
    programs.atuin = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
