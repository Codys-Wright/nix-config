{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
{
  options.${namespace}.bundles.music-production = {
    enable = mkBoolOpt false "Enable music production bundle";
  };

  config = mkIf config.${namespace}.bundles.music-production.enable {
    ${namespace} = {
      music.production.reaper = enabled;
    };
  };
} 