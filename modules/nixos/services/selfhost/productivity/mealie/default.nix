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
  cfg = config.${namespace}.services.selfhost.productivity.mealie;
  selfhostCfg = config.${namespace}.services.selfhost;
in
{
  # disabledModules = [ "services/web-apps/mealie.nix" ];
  # imports = [ "${inputs.unstable}/nixos/modules/services/web-apps/mealie.nix" ];

  options.${namespace}.services.selfhost.productivity.mealie = with types; {
    enable = mkBoolOpt false "Enable Mealie (recipe management)";
    
    url = mkOpt str "mealie.${selfhostCfg.baseDomain}" "URL for Mealie service";
    
    homepage = {
      name = mkOpt str "Mealie" "Name shown on homepage";
      description = mkOpt str "Recipe manager and meal planner" "Description shown on homepage";
      icon = mkOpt str "mealie.svg" "Icon shown on homepage";
      category = mkOpt str "Productivity" "Category on homepage";
    };
  };

  config = mkIf cfg.enable {
    environment.variables = {
      "NLTK_DATA" = "/usr/share/nltk_data";
    };
    services.mealie = {
      enable = true;
      # package = inputs.unstable.legacyPackages.x86_64-linux.mealie;
      port = 8099;
      listenAddress = "127.0.0.1";
      settings = {
        TZ = selfhostCfg.timeZone;
        BASE_URL = "https://${cfg.url}";
        # Optional Ollama integration
        OPENAI_BASE_URL = "http://127.0.0.1:11434/v1";
        OPENAI_API_KEY = "ignore123";
        OPENAI_MODEL = "gemma3:12b";
      };
    };
    
    # Caddy reverse proxy
    services.caddy.virtualHosts."${cfg.url}" = mkIf (selfhostCfg.baseDomain != "") {
      useACMEHost = selfhostCfg.baseDomain;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:8099
      '';
    };
  };
}
