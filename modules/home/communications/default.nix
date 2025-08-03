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
  cfg = config.${namespace}.communications;
in
{
  options.${namespace}.communications = with types; {
    enable = mkBoolOpt false "Enable communications modules";
  };

  config = mkIf cfg.enable {
    # Communications module is enabled
  };
}
