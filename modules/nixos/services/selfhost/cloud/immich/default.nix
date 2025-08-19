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
  cfg = config.${namespace}.services.selfhost.cloud.immich;
  selfhostCfg = config.${namespace}.services.selfhost;
in
{
  options.${namespace}.services.selfhost.cloud.immich = with types; {
    enable = mkBoolOpt false "Enable Immich (photo and video management)";
    
    mediaLocation = mkOpt str "/mnt/storage/immich" "Media storage location for Immich";
    
    url = mkOpt str "photos.${selfhostCfg.baseDomain}" "URL for Immich service";
    
    homepage = {
      name = mkOpt str "Immich" "Name shown on homepage";
      description = mkOpt str "Self-hosted photo and video management solution" "Description shown on homepage";
      icon = mkOpt str "immich.svg" "Icon shown on homepage";
      category = mkOpt str "Cloud" "Category on homepage";
    };
  };

  # Fix until immich is in stable
  # disabledModules = [ "services/web-apps/immich.nix" ];
  # imports = [ "${inputs.unstable}/nixos/modules/services/web-apps/immich.nix" ];

  config = mkIf cfg.enable {
    # Create media directory with proper permissions
    systemd.tmpfiles.rules = [ 
      "d ${cfg.mediaLocation} 0775 immich ${selfhostCfg.group} - -" 
    ];
    
    # Add immich user to video and render groups for hardware acceleration
    users.users.immich.extraGroups = [
      "video"
      "render"
    ];

    services.immich = {
      enable = true;
      port = 3001;
      # package = inputs.unstable.legacyPackages.x86_64-linux.immich;
      host = "127.0.0.1";
      mediaLocation = cfg.mediaLocation;
      group = selfhostCfg.group;

      accelerationDevices = null;

      machine-learning = {
        enable = true;
      };
      redis = {
        enable = true;
        host = "127.0.0.1";
        port = 6379;
      };

      environment = {
        TZ = selfhostCfg.timeZone;
        IMMICH_SERVER_URL = "https://${cfg.url}";
        PUBLIC_IMMICH_SERVER_URL = "https://${cfg.url}";
      };

      database = {
        enable = true;
      };
    };
    
    # Caddy reverse proxy
    services.caddy.virtualHosts."${cfg.url}" = mkIf (selfhostCfg.baseDomain != "") {
      useACMEHost = selfhostCfg.baseDomain;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:3001
      '';
    };
  };
}
