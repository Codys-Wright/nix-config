# Wave 3a: arr stack (6 apps) + vaultwarden (first CNPG consumer).
# Host bridge: <FTS.cluster/wave3a-bridge>. Media/torrent paths mount at
# their ORIGINAL host locations — the sqlite DBs store absolute paths.
{ lib, ... }:
let
  mkSimpleApp = import ../lib/simple-app.nix;
  tz = {
    name = "TZ";
    value = "America/Chicago";
  };
  lsioEnv = [
    tz
    {
      name = "PUID";
      value = "0";
    }
    {
      name = "PGID";
      value = "0";
    }
  ];
  storageMount = {
    name = "operations";
    path = "/mnt/storage/Operations";
    mountPath = "/mnt/storage/Operations";
  };
  arrApp =
    name: sub: port:
    mkSimpleApp {
      inherit name port;
      host = "${sub}.starcommand.live";
      image =
        if name == "readarr" then "blampe/readarr:nightly" else "lscr.io/linuxserver/${name}:latest";
      state = {
        mountPath = "/config";
        size = "5Gi";
      };
      nfsMounts = [ storageMount ];
      auth = true;
      env = lsioEnv;
    };
in
lib.mkMerge [
  (arrApp "radarr" "radarr" 7878)
  (arrApp "sonarr" "sonarr" 8989)
  (arrApp "bazarr" "bazarr" 6767)
  (arrApp "lidarr" "lidarr" 8686)
  (arrApp "jackett" "jackett" 9117)

  # Vaultwarden — first pg-main consumer. Forward-auth stays OFF for the
  # web vault (it has its own auth; /admin protection moves to app-level
  # ADMIN_TOKEN later if wanted).
  (mkSimpleApp {
    name = "vaultwarden";
    host = "vault.starcommand.live";
    image = "vaultwarden/server:1.34.3";
    port = 8222;
    state = {
      mountPath = "/data";
      size = "5Gi";
    };
    env = [
      tz
      {
        name = "DOMAIN";
        value = "https://vault.starcommand.live";
      }
      {
        name = "ROCKET_PORT";
        value = "8222";
      }
      {
        name = "SIGNUPS_ALLOWED";
        value = "false";
      }
      {
        name = "DATABASE_URL";
        valueFrom.secretKeyRef = {
          name = "vaultwarden-secrets";
          key = "database-url";
        };
      }
    ];
  })
]
