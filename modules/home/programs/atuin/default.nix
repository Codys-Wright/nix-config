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
  cfg = config.${namespace}.programs.atuin;
in
{
  options.${namespace}.programs.atuin = with types; {
    enable = mkBoolOpt false "Enable atuin";
  };

  config = mkIf cfg.enable {
    programs.atuin = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
