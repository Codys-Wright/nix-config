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
  cfg = config.${namespace}.services.wanderer;
  backend-port = 8090;
  frontend-port = 3000;
  meilisearch-port = 7700;
  secrets_location = "/run/wanderer/wanderer.env";
in
{
  options.${namespace}.services.wanderer = with types; {
    enable = mkBoolOpt false "Enable wanderer";
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
      "MEILI_DB_PATH" = "/mnt/data/wanderer/data";
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
          ExecStart = "${lib.getExe pkgs.zeus.wanderer-db} serve --http=0.0.0.0:${toString backend-port} --dir=/var/lib/wanderer-db/pb_data";
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
            "ORIGIN=http://apollo:${toString frontend-port}"
            "MEILI_URL=http://127.0.0.1:${toString meilisearch-port}"
            "BODY_SIZE_LIMIT=Infinity"
            "PUBLIC_POCKETBASE_URL=http://apollo:${toString backend-port}"
            #"PUBLIC_DISABLE_SIGNUP=true"
            #"PUBLIC_PRIVATE_INSTANCE=true" # dont allow visitors from viewing trails
            "PUBLIC_VALHALLA_URL=https://valhalla1.openstreetmap.de"
            "PUBLIC_NOMINATIM_URL=https://nominatim.openstreetmap.org"
          ];
        };
      };
    };
  };
}
