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
  cfg = config.${namespace}.services.docker.wanderer;
in
{
  options.${namespace}.services.docker.wanderer = with types; {
    enable = mkBoolOpt false "Enable wanderer docker container";
  };

  config = mkIf cfg.enable {
    # sops
    sops.secrets = {
      meili-master-key = { };
      pocketbase-encryption-key = { };
    };

    # Runtime
    virtualisation.docker = {
      enable = true;
      autoPrune.enable = true;
    };
    virtualisation.oci-containers.backend = "docker";

    # Containers
    virtualisation.oci-containers.containers."wanderer-db" = {
      image = "flomp/wanderer-db";
      environment = {
        # "MEILI_MASTER_KEY" = "$(cat ${config.sops.secrets.meili-master-key.path})";
        "MEILI_URL" = "http://search:7700";
        "ORIGIN" = "http://apollo:3000";
        # "POCKETBASE_ENCRYPTION_KEY" = "$(cat ${config.sops.secrets.pocketbase-encryption-key.path})";
      };
      environmentFiles = [
        config.sops.secrets.meili-master-key.path
        config.sops.secrets.pocketbase-encryption-key.path
      ];
      volumes = [
        "/mnt/data/wanderer/data/pb_data:/pb_data:rw"
      ];
      ports = [
        "8090:8090/tcp"
      ];
      dependsOn = [
        "wanderer-search"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network-alias=db"
        "--network=wanderer_wanderer"
      ];
    };
    systemd.services."docker-wanderer-db" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
        RestartMaxDelaySec = lib.mkOverride 90 "1m";
        RestartSec = lib.mkOverride 90 "100ms";
        RestartSteps = lib.mkOverride 90 9;
      };
      after = [
        "docker-network-wanderer_wanderer.service"
      ];
      requires = [
        "docker-network-wanderer_wanderer.service"
      ];
      partOf = [
        "docker-compose-wanderer-root.target"
      ];
      wantedBy = [
        "docker-compose-wanderer-root.target"
      ];
    };
    virtualisation.oci-containers.containers."wanderer-search" = {
      image = "getmeili/meilisearch:v1.11.3";
      environment = {
        # "MEILI_MASTER_KEY" = "$(cat ${config.sops.secrets.meili-master-key.path})";
        "MEILI_NO_ANALYTICS" = "true";
        "MEILI_URL" = "http://search:7700";
      };
      environmentFiles = [
        config.sops.secrets.meili-master-key.path
      ];
      volumes = [
        "/mnt/data/wanderer/data/data.ms:/meili_data/data.ms:rw"
      ];
      ports = [
        "7700:7700/tcp"
      ];
      log-driver = "journald";
      extraOptions = [
        "--health-cmd=curl --fail http://localhost:7700/health || exit 1"
        "--health-interval=15s"
        "--health-retries=10"
        "--health-start-period=20s"
        "--health-timeout=10s"
        "--network-alias=search"
        "--network=wanderer_wanderer"
      ];
    };
    systemd.services."docker-wanderer-search" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
        RestartMaxDelaySec = lib.mkOverride 90 "1m";
        RestartSec = lib.mkOverride 90 "100ms";
        RestartSteps = lib.mkOverride 90 9;
      };
      after = [
        "docker-network-wanderer_wanderer.service"
      ];
      requires = [
        "docker-network-wanderer_wanderer.service"
      ];
      partOf = [
        "docker-compose-wanderer-root.target"
      ];
      wantedBy = [
        "docker-compose-wanderer-root.target"
      ];
    };
    virtualisation.oci-containers.containers."wanderer-web" = {
      image = "flomp/wanderer-web";
      environment = {
        "BODY_SIZE_LIMIT" = "Infinity";
        # "MEILI_MASTER_KEY" = "$(cat ${config.sops.secrets.meili-master-key.path})";
        "MEILI_URL" = "http://search:7700";
        "ORIGIN" = "http://apollo:3000";
        "PUBLIC_DISABLE_SIGNUP" = "false";
        "PUBLIC_NOMINATIM_URL" = "https://nominatim.openstreetmap.org";
        "PUBLIC_POCKETBASE_URL" = "http://db:8090";
        "PUBLIC_VALHALLA_URL" = "https://valhalla1.openstreetmap.de";
        "UPLOAD_FOLDER" = "/app/uploads";
      };
      environmentFiles = [
        config.sops.secrets.meili-master-key.path
      ];
      volumes = [
        "/mnt/data/wanderer/data/uploads:/app/uploads:rw"
      ];
      ports = [
        "3000:3000/tcp"
      ];
      dependsOn = [
        "wanderer-db"
        "wanderer-search"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network-alias=web"
        "--network=wanderer_wanderer"
      ];
    };
    systemd.services."docker-wanderer-web" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
        RestartMaxDelaySec = lib.mkOverride 90 "1m";
        RestartSec = lib.mkOverride 90 "100ms";
        RestartSteps = lib.mkOverride 90 9;
      };
      after = [
        "docker-network-wanderer_wanderer.service"
      ];
      requires = [
        "docker-network-wanderer_wanderer.service"
      ];
      partOf = [
        "docker-compose-wanderer-root.target"
      ];
      wantedBy = [
        "docker-compose-wanderer-root.target"
      ];
    };

    # Networks
    systemd.services."docker-network-wanderer_wanderer" = {
      path = [ pkgs.docker ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "docker network rm -f wanderer_wanderer";
      };
      script = ''
        docker network inspect wanderer_wanderer || docker network create wanderer_wanderer --driver=bridge
      '';
      partOf = [ "docker-compose-wanderer-root.target" ];
      wantedBy = [ "docker-compose-wanderer-root.target" ];
    };

    # Root service
    # When started, this will automatically create all resources and start
    # the containers. When stopped, this will teardown all resources.
    systemd.targets."docker-compose-wanderer-root" = {
      unitConfig = {
        Description = "Root target generated by compose2nix.";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
