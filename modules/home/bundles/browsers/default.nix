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
  cfg = config.${namespace}.bundles.browsers;
in
{
  options.${namespace}.bundles.browsers = with types; {
    enable = mkBoolOpt false "Whether or not to enable browsers bundle configuration.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # Browser utilities
      firefox
      # chromium  # Removed to avoid collision with ungoogled-chromium
      ungoogled-chromium
    ];

    ${namespace} = {
      programs = {
        zen = enabled;
        brave = enabled;
        librewolf = enabled; # Alternative privacy-focused browser
      };
    };
  };
}
