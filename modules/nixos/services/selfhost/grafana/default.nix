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
  cfg = config.${namespace}.services.selfhost.grafana;
in
{
  options.${namespace}.services.selfhost.grafana = with types; {
    enable = mkBoolOpt false "Enable grafana";
  };

  config = mkIf cfg.enable {
    sops.secrets = {
      garmin-email = {};
      garmin-password = {};
      influxdb-user = {};
      influxdb-password = {};
    };
    services.grafana = {
      enable = true;
      settings = {
        server = {
          http_addr = "0.0.0.0";
          http_port = 3030;
        };
      };
      provision = {
        enable = true;
        dashboards.settings.providers = [
          {
            name = "System Monitor";
            options.path = ./dashboards/system-dashboard.json;
          }
          {
            name = "Garmin Dashboard";
            options.path = ./dashboards/garmin-dashboard.json;
          }
        ];
        datasources.settings.datasources = [
          {
            name = "Prometheus";
            type = "prometheus";
            url = "http://${config.services.prometheus.listenAddress}:${toString config.services.prometheus.port}";
          }
          {
            name = "Garmin-InfluxDB";
            uid = "garmin_influxdb";
            type = "influxdb";
            url = "http://localhost:8086";
            database = "GarminStats";
            user = "$(cat ${config.sops.secrets.influxdb-user.path})";
            secureJasonData = {
              password = "$(cat ${config.sops.secrets.influxdb-password.path})";
            };
          }
        ];
      };
      dataDir = "/mnt/data/grafana";
    };
    services.prometheus = {
      enable = true;
      port = 9991;
      exporters = {
        node = {
          enable = true;
          enabledCollectors = [ "systemd" ];
          port = 9992;
        };
      };

      scrapeConfigs = [
        {
          job_name = "chrysalis";
          static_configs = [
            {
              targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ];
            }
          ];
        }
      ];
    };
    services.influxdb = {
      enable = true;
      dataDir = "/mnt/data/influxdb";
      extraConfig = {
        http = {
          enabled = true;
          bind-address = ":8086";
        };
      };
    };
  };
}
