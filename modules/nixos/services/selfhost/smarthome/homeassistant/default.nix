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
  cfg = config.${namespace}.services.selfhost.smarthome.homeassistant;
  selfhostCfg = config.${namespace}.services.selfhost;
in
{
  options.${namespace}.services.selfhost.smarthome.homeassistant = with types; {
    enable = mkBoolOpt false "Enable Home Assistant (home automation)";
    
    configDir = mkOpt str "${selfhostCfg.mounts.config}/homeassistant" "Configuration directory for Home Assistant";
    
    url = mkOpt str "home.${selfhostCfg.baseDomain}" "URL for Home Assistant service";
    
    homepage = {
      name = mkOpt str "Home Assistant" "Name shown on homepage";
      description = mkOpt str "Home automation platform" "Description shown on homepage";
      icon = mkOpt str "home-assistant.svg" "Icon shown on homepage";
      category = mkOpt str "Smart Home" "Category on homepage";
    };
  };

  config = mkIf cfg.enable {
    # Create config directory
    systemd.tmpfiles.rules = [ 
      "d ${cfg.configDir} 0775 ${selfhostCfg.user} ${selfhostCfg.group} - -" 
    ];
    
    # Caddy reverse proxy
    services.caddy.virtualHosts."${cfg.url}" = mkIf (selfhostCfg.baseDomain != "") {
      useACMEHost = selfhostCfg.baseDomain;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:8123
      '';
    };
    
    # Home Assistant container
    virtualisation.oci-containers = {
      containers = {
        homeassistant = {
          image = "homeassistant/home-assistant:stable";
          autoStart = true;
          extraOptions = [
            "--pull=newer"
          ];
          volumes = [
            "${cfg.configDir}:/config"
          ];
          ports = [
            "127.0.0.1:8123:8123"
            "127.0.0.1:8124:80"
          ];
          environment = {
            TZ = selfhostCfg.timeZone;
            PUID = toString config.users.users.${selfhostCfg.user}.uid;
            PGID = toString config.users.groups.${selfhostCfg.group}.gid;
          };
        };
      };
    };
  };
} 