# Auth stack — the SSO backbone, moved off selfhostblocks into the cluster.
# Built in stages: LLDAP first (this file), Authelia + redis follow.
#
#   lldap   lldap/lldap:v0.6.2  (LDAP :3890, web UI :17170)
#
# Data (users.db + server_key + jwt_secret_file) is migrated from the host
# /var/lib/lldap into the db-local PVC; same 0.6.2 version, schema-compatible.
# SQLite stays on db-local (NOT NFS — SQLite corrupts on the all_squash NAS),
# pinned to starcommand like the other stateful pods.
#
# Secrets (LLDAP_JWT_SECRET, LLDAP_LDAP_USER_PASS) come from the host bridge
# as the `lldap-secrets` Secret. Host bridge: <FTS.cluster/auth-bridge>.
#
# Public ldap.starcommand.live Ingress is intentionally NOT added yet — the
# host still serves it until the Authelia cutover, to avoid a split brain.
{ ... }:
let
  image = "lldap/lldap:v0.6.2";
  secretEnv = key: {
    name = key;
    valueFrom.secretKeyRef = {
      name = "lldap-secrets";
      inherit key;
    };
  };
in
{
  applications.auth = {
    namespace = "auth";
    createNamespace = true;

    resources = {
      persistentVolumeClaims."lldap-data".spec = {
        accessModes = [ "ReadWriteOnce" ];
        storageClassName = "db-local";
        resources.requests.storage = "1Gi";
      };

      deployments.lldap.spec = {
        replicas = 1;
        strategy.type = "Recreate";
        selector.matchLabels.app = "lldap";
        template = {
          metadata.labels.app = "lldap";
          spec = {
            enableServiceLinks = false;
            nodeSelector."kubernetes.io/hostname" = "starcommand";
            # The image ships a default lldap_config.toml with an ACTIVE
            # placeholder `key_seed`, which conflicts with the migrated
            # server_key file (where the host's OPAQUE passwords are anchored)
            # and makes LLDAP refuse to start ("private key has changed").
            # Overwrite it each boot with a clean, seedless config that pins
            # the key to the migrated file. Idempotent; survives PVC/pod
            # recreation.
            initContainers.seed-config = {
              inherit image;
              command = [
                "sh"
                "-c"
                ''
                  cat > /data/lldap_config.toml <<'EOF'
                  database_url = "sqlite:///data/users.db?mode=rwc"
                  ldap_base_dn = "dc=starcommand,dc=live"
                  key_file = "/data/server_key"
                  EOF
                ''
              ];
              volumeMounts = [
                {
                  name = "data";
                  mountPath = "/data";
                }
              ];
            };
            containers.lldap = {
              inherit image;
              ports = {
                ldap.containerPort = 3890;
                web.containerPort = 17170;
              };
              env = [
                {
                  name = "LLDAP_LDAP_BASE_DN";
                  value = "dc=starcommand,dc=live";
                }
                {
                  name = "LLDAP_DATABASE_URL";
                  value = "sqlite:///data/users.db?mode=rwc";
                }
                # Bind to all interfaces inside the pod.
                {
                  name = "LLDAP_HTTP_HOST";
                  value = "0.0.0.0";
                }
                {
                  name = "LLDAP_LDAP_HOST";
                  value = "0.0.0.0";
                }
                (secretEnv "LLDAP_JWT_SECRET")
                (secretEnv "LLDAP_LDAP_USER_PASS")
              ];
              volumeMounts = [
                {
                  name = "data";
                  mountPath = "/data";
                }
              ];
            };
            volumes = [
              {
                name = "data";
                persistentVolumeClaim.claimName = "lldap-data";
              }
            ];
          };
        };
      };

      services.lldap.spec = {
        selector.app = "lldap";
        ports = {
          ldap = {
            port = 3890;
            targetPort = 3890;
          };
          web = {
            port = 17170;
            targetPort = 17170;
          };
        };
      };
    };
  };
}
