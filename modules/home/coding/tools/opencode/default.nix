{
  options,
  config,
  lib,
  pkgs,
  namespace,
  inputs,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.coding.tools.opencode;
in
{
  options.${namespace}.coding.tools.opencode = with types; {
    enable = mkBoolOpt false "Enable OpenCode AI terminal assistant";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      opencode
    ];
  };
}
