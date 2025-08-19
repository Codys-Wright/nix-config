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
  cfg = config.${namespace}.services.selfhost.productivity.wanderer;
  selfhostCfg = config.${namespace}.services.selfhost;
  backend-port = 8090;
  frontend-port = 3000;
  meilisearch-port = 7700;
  secrets_location = "/run/wanderer/wanderer.env";
in
{
  options.${namespace}.services.selfhost.productivity.wanderer = with types; {
    enable = mkBoolOpt false "Enable Wanderer (hiking trail planner)";
    
    url = mkOpt str "wanderer.${selfhostCfg.baseDomain}" "URL for Wanderer service";
    
    dataDir = mkOpt str "/mnt/data/wanderer" "Data directory for Wanderer";
    
    homepage = {
      name = mkOpt str "Wanderer" "Name shown on homepage";
      description = mkOpt str "Self-hosted trail database and hiking planner" "Description shown on homepage";
      icon = mkOpt str "wanderer.svg" "Icon shown on homepage";
      category = mkOpt str "Productivity" "Category on homepage";
    };
  };

  config = mkIf cfg.enable {
    sops.secrets.meili-master-key = { };

    environment.systemPackages = (
      with pkgs.zeus;
      [
        wanderer-db
        wanderer-web
      ]
    );
    environment.variables = {
      "MEILI_DB_PATH" = "${cfg.dataDir}/data";
    };
    services.meilisearch = {
      enable = true;
      package = pkgs.meilisearch;
      listenPort = meilisearch-port;
      masterKeyEnvironmentFile = secrets_location; # config.sops.secrets.meili-master-key.path;
    };
    systemd.services = {
      wanderer-db = {
        description = "Wanderer backend service";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          ExecStart = "${lib.getExe pkgs.zeus.wanderer-db} serve --http=127.0.0.1:${toString backend-port} --dir=/var/lib/wanderer-db/pb_data";
          DynamicUser = true;
          StateDirectory = [
            "wanderer-db"
            "wanderer-db/pb_data"
          ];
          WorkingDirectory = "/var/lib/wanderer-db/pb_data";
          EnvironmentFile = secrets_location; # config.sops.secrets.meili-master-key.path;
          Environment = "MEILI_URL=http://127.0.0.1:${toString meilisearch-port}";

          ExecStartPre = "${lib.getExe (
            pkgs.writeShellScriptBin "wanderer_add_migrations_startup" ''
              if [ ! -e /var/lib/wanderer-db/pb_data/migrations ]; then
                cp -r ${pkgs.zeus.wanderer-db}/share/* /var/lib/wanderer-db/pb_data/
                chown -R --reference=/var/lib/wanderer-db/pb_data /var/lib/wanderer-db/pb_data/*
              fi
            ''
          )}";
        };
      };

      wanderer-web = {
        description = "Wanderer frontend service";
        after = [
          "network.target"
          "wanderer-db.service"
        ];
        requires = [ "wanderer-db.service" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          ExecStart = lib.getExe pkgs.zeus.wanderer-web;
          EnvironmentFile = secrets_location; # config.sops.secrets.meili-master-key.path;
          Environment = [
            "ORIGIN=https://${cfg.url}"
            "MEILI_URL=http://127.0.0.1:${toString meilisearch-port}"
            "BODY_SIZE_LIMIT=Infinity"
            "PUBLIC_POCKETBASE_URL=https://${cfg.url}/api"
            "PORT=${toString frontend-port}"
            "HOST=127.0.0.1"
            #"PUBLIC_DISABLE_SIGNUP=true"
            #"PUBLIC_PRIVATE_INSTANCE=true" # dont allow visitors from viewing trails
            "PUBLIC_VALHALLA_URL=https://valhalla1.openstreetmap.de"
            "PUBLIC_NOMINATIM_URL=https://nominatim.openstreetmap.org"
          ];
        };
      };
    };
    
    # Caddy reverse proxy
    services.caddy.virtualHosts."${cfg.url}" = mkIf (selfhostCfg.baseDomain != "") {
      useACMEHost = selfhostCfg.baseDomain;
      extraConfig = ''
        handle /api/* {
          reverse_proxy http://127.0.0.1:${toString backend-port}
        }
        handle {
          reverse_proxy http://127.0.0.1:${toString frontend-port}
        }
      '';
    };
  };
}
