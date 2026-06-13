# Declaration of every cluster Secret — the single source of truth consumed by
# BOTH `just gen-secrets` (which decrypts the nix-secrets values, builds the k8s
# Secret manifests, and sops-encrypts them to k8s/secrets/<name>.enc.yaml) and
# k8s/apps/cluster-secrets.nix (which references the generated files via
# extraRawYamls). Add a secret here, run `just gen-secrets`, done — no plaintext
# ever touches Nix or git.
#
# Value forms:
#   { sops = "a/b/c"; }                      -> value at that nix-secrets path
#   { literal = "x"; }                       -> a constant
#   { template = "...{v}..."; vars.v = "a/b"; } -> string with sops vars substituted
#
# Each top-level entry -> one k8s/secrets/<name>.enc.yaml (may hold several
# Secret docs). `data` values are raw base64 (k8s data:); `stringData` is plaintext.
let
  apps = "starcommand/selfhost/apps";
  auth = "starcommand/selfhost/auth";
in
{
  pinchflat.secrets = [
    {
      name = "pinchflat-secrets";
      namespace = "selfhost";
      stringData."secret-key-base".sops = "${apps}/pinchflat/secret_key_base";
    }
  ];

  argocd-oidc.secrets = [
    {
      name = "argocd-oidc";
      namespace = "argocd";
      labels."app.kubernetes.io/part-of" = "argocd";
      stringData."client-secret".sops = "${apps}/argocd/sso_secret";
    }
  ];

  external-dns-cloudflare.secrets = [
    {
      name = "external-dns-cloudflare";
      namespace = "external-dns";
      stringData."api-token".sops = "starcommand/selfhost/proxy/cloudflare/starcommand_dns_key";
    }
  ];

  karakeep.secrets = [
    {
      name = "karakeep-secrets";
      namespace = "selfhost";
      stringData = {
        "nextauth-secret".sops = "${apps}/karakeep/nextauth_secret";
        "meili-master-key".sops = "${apps}/karakeep/meilisearch_master_key";
        "oauth-client-secret".sops = "${apps}/karakeep/sso_secret";
      };
    }
  ];

  vaultwarden.secrets = [
    {
      name = "vaultwarden-pg";
      namespace = "databases";
      type = "kubernetes.io/basic-auth";
      labels."cnpg.io/reload" = "true";
      stringData = {
        username.literal = "vaultwarden";
        password.sops = "${apps}/vaultwarden/k8s_db_password";
      };
    }
    {
      name = "vaultwarden-secrets";
      namespace = "selfhost";
      stringData."database-url" = {
        template = "postgresql://vaultwarden:{p}@pg-main-rw.databases.svc:5432/vaultwarden";
        vars.p = "${apps}/vaultwarden/k8s_db_password";
      };
    }
  ];

  grafana-secrets.secrets = [
    {
      name = "grafana-secrets";
      namespace = "observability";
      stringData = {
        admin-user.literal = "admin";
        admin-password.sops = "starcommand/selfhost/monitoring/grafana/admin_password";
        GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET.sops = "starcommand/selfhost/monitoring/grafana/oidc_secret";
      };
    }
  ];

  invoiceninja.secrets = [
    {
      name = "invoiceninja-secrets";
      namespace = "selfhost";
      stringData = {
        # APP_KEY needs the literal "base64:" prefix the old shb module added.
        APP_KEY = {
          template = "base64:{k}";
          vars.k = "${apps}/invoiceninja/app_key";
        };
        DB_PASSWORD1.sops = "${apps}/invoiceninja/db_password";
      };
    }
  ];

  deluge-vpn.secrets = [
    {
      name = "gluetun-creds";
      namespace = "selfhost";
      stringData = {
        OPENVPN_USER.sops = "starcommand/selfhost/openvpn/username";
        OPENVPN_PASSWORD.sops = "starcommand/selfhost/openvpn/password";
      };
    }
  ];

  open-webui-oauth.secrets = [
    {
      name = "open-webui-oauth";
      namespace = "ai";
      stringData."client-secret".sops = "${apps}/open-webui/sso_secret";
    }
  ];

  forgejo.secrets = [
    {
      name = "forgejo-pg";
      namespace = "databases";
      type = "kubernetes.io/basic-auth";
      labels."cnpg.io/reload" = "true";
      stringData = {
        username.literal = "forgejo";
        password.sops = "${apps}/forgejo/k8s_db_password";
      };
    }
    {
      name = "forgejo-db";
      namespace = "forgejo";
      stringData.password.sops = "${apps}/forgejo/k8s_db_password";
    }
  ];

  auth.secrets = [
    {
      name = "lldap-secrets";
      namespace = "auth";
      stringData = {
        LLDAP_LDAP_USER_PASS.sops = "${auth}/lldap/admin_password";
        LLDAP_JWT_SECRET.sops = "${auth}/lldap/jwt_secret";
      };
    }
    {
      name = "authelia-pg";
      namespace = "databases";
      type = "kubernetes.io/basic-auth";
      labels."cnpg.io/reload" = "true";
      stringData = {
        username.literal = "authelia";
        password.sops = "${auth}/authelia/k8s_db_password";
      };
    }
    {
      name = "authelia-secrets";
      namespace = "auth";
      stringData = {
        jwt_secret.sops = "${auth}/authelia/jwt_secret";
        session_secret.sops = "${auth}/authelia/session_secret";
        storage_encryption_key.sops = "${auth}/authelia/storage_encryption_key";
        oidc_hmac_secret.sops = "${auth}/authelia/oidc_hmac_secret";
        # the authelia ldap bind reuses the LLDAP admin password (the host bridge
        # set .key to lldap/admin_password) — point straight at the real value.
        ldap_admin_password.sops = "${auth}/lldap/admin_password";
        db_password.sops = "${auth}/authelia/k8s_db_password";
        nextcloud_client_secret.sops = "${apps}/nextcloud/sso_secret";
        immich_client_secret.sops = "${apps}/immich/sso_secret";
        jellyfin_client_secret.sops = "${apps}/jellyfin/sso_secret";
        audiobookshelf_client_secret.sops = "${apps}/audiobookshelf/sso_secret";
        forgejo_client_secret.sops = "${apps}/forgejo/sso_secret";
        karakeep_client_secret.sops = "${apps}/karakeep/sso_secret";
        "open-webui_client_secret".sops = "${apps}/open-webui/sso_secret";
        argocd_client_secret.sops = "${apps}/argocd/sso_secret";
        grafana_client_secret.sops = "starcommand/selfhost/monitoring/grafana/oidc_secret";
      };
      # base64 value (k8s data:) — nix-secrets stores it already-base64.
      data.oidc_issuer_private_key.sops = "${auth}/authelia/oidc_issuer_private_key_b64";
    }
  ];

  nextcloud.secrets = [
    {
      name = "nextcloud-pg";
      namespace = "databases";
      type = "kubernetes.io/basic-auth";
      labels."cnpg.io/reload" = "true";
      stringData = {
        username.literal = "nextcloud";
        password.sops = "${apps}/nextcloud/k8s_db_password";
      };
    }
    {
      name = "nextcloud-config";
      namespace = "nextcloud";
      stringData."config.php" = {
        template = ''
          <?php
          $CONFIG = array (
            'instanceid' => 'oc72wlrxrkoz',
            'passwordsalt' => '{psalt}',
            'secret' => '{secret}',
            'trusted_domains' => array ( 0 => 'cloud.starcommand.live', 1 => 'cloud.fasttrackaudio.com' ),
            'datadirectory' => '/mnt/storage/Operations/nextcloud-data/data',
            'dbtype' => 'pgsql',
            'dbname' => 'nextcloud',
            'dbhost' => 'pg-main-rw.databases.svc:5432',
            'dbuser' => 'nextcloud',
            'dbpassword' => '{pw}',
            'dbtableprefix' => 'oc_',
            'redis' => array ( 'host' => 'nextcloud-redis', 'port' => 6379 ),
            'memcache.local' => '\OC\Memcache\APCu',
            'memcache.distributed' => '\OC\Memcache\Redis',
            'memcache.locking' => '\OC\Memcache\Redis',
            'overwrite.cli.url' => 'https://cloud.starcommand.live',
            'overwriteprotocol' => 'https',
            'overwritehost' => 'cloud.starcommand.live',
            'trusted_proxies' => array ( 0 => '10.42.0.0/16' ),
            'default_phone_region' => 'US',
            'maintenance' => false,
            'installed' => true,
          );
        '';
        vars = {
          psalt = "${apps}/nextcloud/passwordsalt";
          secret = "${apps}/nextcloud/secret";
          pw = "${apps}/nextcloud/k8s_db_password";
        };
      };
    }
  ];
}
