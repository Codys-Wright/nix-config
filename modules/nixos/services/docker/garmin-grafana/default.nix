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
  cfg = config.${namespace}.services.docker.garmin-grafana;
in
{
  options.${namespace}.services.docker.garmin-grafana = with types; {
    enable = mkBoolOpt false "Enable garmin-grafana";
  };

  config = mkIf cfg.enable {
    sops.secrets = {
      garmin-email = { };
      garmin-password = { };
      influxdb-user = { };
      influxdb-password = { };
    };
    # Runtime
    virtualisation.docker = {
      enable = true;
      autoPrune.enable = true;
    };
    virtualisation.oci-containers.backend = "docker";

    # Containers
    virtualisation.oci-containers.containers."garmin-fetch-data" = {
      image = "thisisarpanghosh/garmin-fetch-data:latest";
      environment = {
        "GARMINCONNECT_IS_CN" = "False";
        "INFLUXDB_DATABASE" = "GarminStats";
        "INFLUXDB_HOST" = "influxdb";
        "INFLUXDB_PASSWORD" = "$(cat ${config.sops.secrets.influxdb-password.path})";
        "INFLUXDB_PORT" = "8086";
        "INFLUXDB_USERNAME" = "$(cat ${config.sops.secrets.influxdb-user.path})";
        # "GARMINCONNECT_EMAIL" = "$(cat ${config.sops.secrets.garmin-email.path})";
        # "GARMINCONNECT_BASE64_PASSWORD" = "$(cat ${config.sops.secrets.garmin-password.path})";
      };
      volumes = [
        "/mnt/data/garmin/garminconnect-tokens:/home/appuser/.garminconnect:rw"
      ];
      dependsOn = [
        "influxdb"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network-alias=garmin-fetch-data"
        "--network=garmin-grafana_default"
      ];
    };
    systemd.services."docker-garmin-fetch-data" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
        RestartMaxDelaySec = lib.mkOverride 90 "1m";
        RestartSec = lib.mkOverride 90 "100ms";
        RestartSteps = lib.mkOverride 90 9;
      };
      after = [
        "docker-network-garmin-grafana_default.service"
      ];
      requires = [
        "docker-network-garmin-grafana_default.service"
      ];
      partOf = [
        "docker-compose-garmin-grafana-root.target"
      ];
      wantedBy = [
        "docker-compose-garmin-grafana-root.target"
      ];
    };
    virtualisation.oci-containers.containers."grafana" = {
      image = "grafana/grafana:latest";
      environment = {
        "GF_DATE_FORMATS_FULL_DATE" = "Do MMMM YYYY - HH:mm:ss";
        "GF_DATE_FORMATS_INTERVAL_DAY" = "DD MMM";
        "GF_DATE_FORMATS_INTERVAL_HOUR" = "DD MMM HH:mm";
        "GF_DATE_FORMATS_INTERVAL_MINUTE" = "HH:mm";
        "GF_DATE_FORMATS_INTERVAL_MONTH" = "YYYY-MM";
        "GF_DATE_FORMATS_INTERVAL_SECOND" = "HH:mm:ss";
        "GF_DATE_FORMATS_INTERVAL_YEAR" = "YYYY";
        "GF_PLUGINS_PREINSTALL" = "marcusolsson-hourly-heatmap-panel";
        "GF_SECURITY_ADMIN_PASSWORD" = "admin";
        "GF_SECURITY_ADMIN_USER" = "admin";
      };
      volumes = [
        "/mnt/data/garmin/Grafana_Dashboard:/etc/grafana/provisioning/dashboards:rw"
        "/mnt/data/garmin/Grafana_Datasource:/etc/grafana/provisioning/datasources:rw"
        "/mnt/data/garmin/garmin-grafana_grafana_data:/var/lib/grafana:rw"
      ];
      ports = [
        "3030:3000/tcp"
      ];
      log-driver = "journald";
      extraOptions = [
        "--hostname=grafana"
        "--network-alias=grafana"
        "--network=garmin-grafana_default"
      ];
    };
    systemd.services."docker-grafana" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
        RestartMaxDelaySec = lib.mkOverride 90 "1m";
        RestartSec = lib.mkOverride 90 "100ms";
        RestartSteps = lib.mkOverride 90 9;
      };
      after = [
        "docker-network-garmin-grafana_default.service"
        "docker-volume-garmin-grafana_grafana_data.service"
      ];
      requires = [
        "docker-network-garmin-grafana_default.service"
        "docker-volume-garmin-grafana_grafana_data.service"
      ];
      partOf = [
        "docker-compose-garmin-grafana-root.target"
      ];
      wantedBy = [
        "docker-compose-garmin-grafana-root.target"
      ];
    };
    virtualisation.oci-containers.containers."influxdb" = {
      image = "influxdb:1.11";
      environment = {
        "INFLUXDB_DATA_INDEX_VERSION" = "tsi1";
        "INFLUXDB_DB" = "GarminStats";
        "INFLUXDB_USER" = "$(cat ${config.sops.secrets.influxdb-user.path})";
        "INFLUXDB_USER_PASSWORD" = "$(cat ${config.sops.secrets.influxdb-password.path})";
      };
      volumes = [
        "/mnt/data/garmin/influxdb_data:/var/lib/influxdb:rw"
      ];
      log-driver = "journald";
      extraOptions = [
        "--hostname=influxdb"
        "--network-alias=influxdb"
        "--network=garmin-grafana_default"
      ];
    };
    systemd.services."docker-influxdb" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
        RestartMaxDelaySec = lib.mkOverride 90 "1m";
        RestartSec = lib.mkOverride 90 "100ms";
        RestartSteps = lib.mkOverride 90 9;
      };
      after = [
        "docker-network-garmin-grafana_default.service"
      ];
      requires = [
        "docker-network-garmin-grafana_default.service"
      ];
      partOf = [
        "docker-compose-garmin-grafana-root.target"
      ];
      wantedBy = [
        "docker-compose-garmin-grafana-root.target"
      ];
    };

    # Networks
    systemd.services."docker-network-garmin-grafana_default" = {
      path = [ pkgs.docker ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "docker network rm -f garmin-grafana_default";
      };
      script = ''
        docker network inspect garmin-grafana_default || docker network create garmin-grafana_default
      '';
      partOf = [ "docker-compose-garmin-grafana-root.target" ];
      wantedBy = [ "docker-compose-garmin-grafana-root.target" ];
    };

    # Volumes
    systemd.services."docker-volume-garmin-grafana_grafana_data" = {
      path = [ pkgs.docker ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        docker volume inspect garmin-grafana_grafana_data || docker volume create garmin-grafana_grafana_data
      '';
      partOf = [ "docker-compose-garmin-grafana-root.target" ];
      wantedBy = [ "docker-compose-garmin-grafana-root.target" ];
    };

    # Root service
    # When started, this will automatically create all resources and start
    # the containers. When stopped, this will teardown all resources.
    systemd.targets."docker-compose-garmin-grafana-root" = {
      unitConfig = {
        Description = "Root target generated by compose2nix.";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
