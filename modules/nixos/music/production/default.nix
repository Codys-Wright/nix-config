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
  cfg = config.${namespace}.music.production;
in
{
  options.${namespace}.music.production = with types; {
    enable = mkBoolOpt false "Enable music production environment at system level";
  };

  config = mkIf cfg.enable {
    # The individual modules (musnix, reaper, plugins) will handle their own enable/disable logic
    # when this module is enabled, they will be automatically enabled by snowfall-lib

    ${namespace} = {
      music.production = {
        musnix = enabled;
        daw.reaper = enabled;

        plugins = {
          lsp = enabled;
          fabfilter = enabled;
          yabridge = enabled;
        };
      };
    };
  };
} 