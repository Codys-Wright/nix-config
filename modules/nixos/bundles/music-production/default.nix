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
  cfg = config.${namespace}.bundles.music-production;
in
{
  options.${namespace}.bundles.music-production = with types; {
    enable = mkBoolOpt false "Whether or not to enable music production configuration.";
  };

  config = mkIf cfg.enable {
    # Enable the system-level music production environment
    ${namespace}.music.production = enabled;
  };
}
