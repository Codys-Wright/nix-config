{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
{
  options.${namespace}.bundles.music = {
    enable = mkBoolOpt false "Enable music bundle";
  };

  config = mkIf config.${namespace}.bundles.music.enable {
    ${namespace} = {
      music.spotify = enabled;
    };
  };
} 