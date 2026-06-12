# Wave 1 migrations (selfhostblocks → cluster): pinchflat, audiobookshelf,
# hledger, grocy, jdownloader. Deluge is deferred (needs a VPN sidecar).
#
# Host-side counterpart: starcommand <FTS.cluster/wave1-bridge> (Authelia
# rules + LDAP groups + pinchflat secret).
# Data migration: rsync old /var/lib state into /mnt/storage/k8s/selfhost-*.
{ lib, ... }:
let
  mkSimpleApp = import ../lib/simple-app.nix;
  tz = {
    name = "TZ";
    value = "America/Chicago";
  };
in
lib.mkMerge [
  # Pinchflat — youtube archiver. Forward-auth (one_factor, pinchflat_user).
  (mkSimpleApp {
    name = "pinchflat";
    host = "youtube.starcommand.live";
    image = "ghcr.io/kieraneglin/pinchflat:latest";
    port = 8945;
    state = {
      mountPath = "/config";
      size = "5Gi";
    };
    nfsMounts = [
      {
        name = "media";
        path = "/mnt/storage/Operations/youtube";
        # same path as on the host: pinchflat's DB stores absolute paths
        mountPath = "/mnt/storage/Operations/youtube";
      }
    ];
    auth = true;
    env = [
      tz
      {
        name = "SECRET_KEY_BASE";
        valueFrom.secretKeyRef = {
          name = "pinchflat-secrets";
          key = "secret-key-base";
        };
      }
    ];
  })

  # Audiobookshelf — native OIDC lives in its own migrated DB; the Authelia
  # client is re-registered host-side (claims policy reduced to default,
  # roles managed in-app).
  (mkSimpleApp {
    name = "audiobookshelf";
    host = "audiobooks.starcommand.live";
    image = "ghcr.io/advplyr/audiobookshelf:latest";
    port = 80;
    state = {
      mountPath = "/config";
      size = "5Gi";
    };
    nfsMounts = [
      {
        name = "metadata-media";
        path = "/mnt/storage/Operations/media/audiobooks";
        # same path as on the host: abs library config stores absolute paths
        mountPath = "/mnt/storage/Operations/media/audiobooks";
      }
    ];
    env = [
      tz
      {
        name = "METADATA_PATH";
        value = "/config/metadata";
      }
      {
        name = "CONFIG_PATH";
        value = "/config/config";
      }
    ];
  })

  # hledger-web — journal on the PVC. two_factor forward-auth.
  (mkSimpleApp {
    name = "hledger";
    host = "finance.starcommand.live";
    image = "dastapov/hledger:latest";
    port = 5000;
    state = {
      mountPath = "/data";
      size = "1Gi";
    };
    auth = true;
    env = [
      tz
      {
        name = "HLEDGER_JOURNAL_FILE";
        value = "/data/hledger.journal";
      }
      {
        name = "HLEDGER_BASE_URL";
        value = "https://finance.starcommand.live";
      }
      {
        name = "HLEDGER_ARGS";
        value = "--allow=edit --forecast";
      }
      {
        name = "HOME";
        value = "/data";
      }
    ];
  })

  # Grocy — lsio image, sqlite under /config. App has its own login; the
  # old deployment had no proxy auth, add forward-auth for parity with the
  # wildcard two_factor rule.
  (mkSimpleApp {
    name = "grocy";
    host = "grocy.starcommand.live";
    image = "lscr.io/linuxserver/grocy:latest";
    port = 80;
    state = {
      mountPath = "/config";
      size = "2Gi";
    };
    auth = true;
    env = [
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
  })

  # JDownloader — same image as the old podman deployment; straight lift.
  (mkSimpleApp {
    name = "jdownloader";
    host = "jdownloader.starcommand.live";
    image = "jlesage/jdownloader-2:latest";
    port = 5800;
    state = {
      mountPath = "/config";
      size = "5Gi";
    };
    nfsMounts = [
      {
        name = "output";
        path = "/mnt/storage/Operations/downloads";
        mountPath = "/output";
      }
    ];
    auth = true;
    env = [
      tz
      {
        name = "KEEP_APP_RUNNING";
        value = "1";
      }
      {
        name = "CLEAN_TMP_DIR";
        value = "1";
      }
      {
        name = "DARK_MODE";
        value = "1";
      }
      {
        name = "JD_JAVA_OPTIONS";
        value = "-Xms256m -Xmx1024m";
      }
    ];
  })
]
