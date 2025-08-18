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
  cfg = config.${namespace}.services.selfhost.mealie;
in
{
  # disabledModules = [ "services/web-apps/mealie.nix" ];
  # imports = [ "${inputs.unstable}/nixos/modules/services/web-apps/mealie.nix" ];

  options.${namespace}.services.selfhost.mealie = with types; {
    enable = mkBoolOpt false "Enable mealie";
  };

  config = mkIf cfg.enable {
    environment.variables = {
      "NLTK_DATA" = "/usr/share/nltk_data";
    };
    services.mealie = {
      enable = true;
      # package = inputs.unstable.legacyPackages.x86_64-linux.mealie;
      port = 8099;
      listenAddress = "0.0.0.0";
      settings = {
        TZ = "Europe/Zurich";
        OPENAI_BASE_URL = "http://apollo:11434/v1";
        OPENAI_API_KEY = "ignore123";
        OPENAI_MODEL = "gemma3:12b";
      };
    };
  };
}
