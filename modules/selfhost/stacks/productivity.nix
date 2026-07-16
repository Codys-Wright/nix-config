# Productivity stack: Nextcloud, monitoring, Vaultwarden, Grocy, Forgejo,
# Karakeep, Hledger, Home-Assistant, Open-WebUI
{
  fleet,
  ...
}:
let
  inherit (import ../_data/vars.nix)
    domain
    authSubdomain
    nextcloudSubdomain
    grafanaSubdomain
    vaultwardenSubdomain
    grocySubdomain
    forgejoSubdomain
    karakeepSubdomain
    hledgerSubdomain
    homeAssistantSubdomain
    openWebuiSubdomain
    ;
in
{
  fleet.selfhost._.stack-productivity = {
    description = "Productivity stack: Nextcloud, monitoring, Vaultwarden, Grocy, Forgejo, Karakeep, Hledger, Home-Assistant, Open-WebUI";

    includes = [
      # Nextcloud Server
      (fleet.selfhost._.nextcloud {
        inherit domain;
        subdomain = nextcloudSubdomain;
        # App/config stays on btrfs for proper permissions
        dataDir = "/var/lib/nextcloud";
        adminPasswordKey = "starcommand/selfhost/apps/nextcloud/admin_password";

        # External Storage - merged storage and Synology NAS
        externalStorage = {
          userLocalMount = {
            directory = "/mnt/storage";
            mountName = "storage"; # Appears as "storage" folder in Nextcloud
          };
          localMounts = {
            synologyMedia = {
              directory = "/mnt/synology-vault";
              mountName = "synology-media"; # Appears as "synology-media" folder in Nextcloud
            };
          };
        };

        # LDAP integration
        ldap = {
          enable = true;
          port = 3890; # Same as LLDAP
          dcdomain = "dc=${builtins.replaceStrings [ "." ] [ ",dc=" ] domain}";
          adminPasswordKey = "starcommand/selfhost/apps/nextcloud/ldap_admin_password";
          userGroup = "nextcloud_user";
        };

        # SSO integration
        sso = {
          enable = true;
          endpoint = "https://${authSubdomain}.${domain}";
          clientID = "nextcloud";
          secretKey = "starcommand/selfhost/apps/nextcloud/sso_secret";
          secretForAutheliaKey = "starcommand/selfhost/auth/authelia/nextcloud_sso_secret";
        };
      })

      # Monitoring Stack
      (fleet.selfhost._.monitoring {
        inherit domain;
        subdomain = grafanaSubdomain;
        adminPasswordKey = "starcommand/selfhost/monitoring/grafana/admin_password";
        secretKeyKey = "starcommand/selfhost/monitoring/grafana/secret_key";
        contactPoints = [ "acodywright@gmail.com" ];

        # LDAP integration
        ldap = {
          userGroup = "grafana_user";
          adminGroup = "grafana_admin";
        };

        # SSO integration
        sso = {
          enable = true;
          authEndpoint = "https://${authSubdomain}.${domain}";
          sharedSecretKey = "starcommand/selfhost/monitoring/grafana/oidc_secret";
          sharedSecretForAutheliaKey = "starcommand/selfhost/monitoring/grafana/oidc_secret_for_authelia";
        };
      })

      # Vaultwarden Password Manager
      (fleet.selfhost._.vaultwarden {
        inherit domain;
        subdomain = vaultwardenSubdomain;
        databasePasswordKey = "starcommand/selfhost/apps/vaultwarden/database_password";
        authEndpoint = "https://${authSubdomain}.${domain}";
      })

      # Grocy - Grocery and household management
      (fleet.selfhost._.grocy {
        inherit domain;
        subdomain = grocySubdomain;
        currency = "USD";
        culture = "en";
      })

      # Forgejo - Git hosting
      (fleet.selfhost._.forgejo {
        inherit domain;
        subdomain = forgejoSubdomain;
        databasePasswordKey = "starcommand/selfhost/apps/forgejo/database_password";
        # LDAP
        ldapDcdomain = "dc=${builtins.replaceStrings [ "." ] [ ",dc=" ] domain}";
        ldapAdminPasswordKey = "starcommand/selfhost/apps/forgejo/ldap_admin_password";
        ldapUserGroup = "forgejo_user";
        ldapAdminGroup = "forgejo_admin";
        # SSO
        authEndpoint = "https://${authSubdomain}.${domain}";
        ssoSecretKey = "starcommand/selfhost/apps/forgejo/sso_secret";
        ssoSecretForAutheliaKey = "starcommand/selfhost/auth/authelia/forgejo_sso_secret";
      })

      # Karakeep - AI-powered bookmarking
      (fleet.selfhost._.karakeep {
        inherit domain;
        subdomain = karakeepSubdomain;
        nextauthSecretKey = "starcommand/selfhost/apps/karakeep/nextauth_secret";
        meilisearchMasterKeyKey = "starcommand/selfhost/apps/karakeep/meilisearch_master_key";
        # SSO
        authEndpoint = "https://${authSubdomain}.${domain}";
        ssoSecretKey = "starcommand/selfhost/apps/karakeep/sso_secret";
        ssoSecretForAutheliaKey = "starcommand/selfhost/auth/authelia/karakeep_sso_secret";
      })

      # Hledger - Plain-text accounting
      (fleet.selfhost._.hledger {
        inherit domain;
        subdomain = hledgerSubdomain;
        authEndpoint = "https://${authSubdomain}.${domain}";
      })

      # Home-Assistant - Home automation
      (fleet.selfhost._.home-assistant {
        inherit domain;
        subdomain = homeAssistantSubdomain;
        name = "Star Command Home";
        country = "US";
        latitude = "0.0";
        longitude = "0.0";
        time_zone = "America/Chicago";
        unit_system = "us_customary";
        ldap = {
          userGroup = "homeassistant_user";
        };
      })

      # Open-WebUI - LLM chat interface
      (fleet.selfhost._.open-webui {
        inherit domain;
        subdomain = openWebuiSubdomain;
        # SSO
        authEndpoint = "https://${authSubdomain}.${domain}";
        ssoSecretKey = "starcommand/selfhost/apps/open-webui/sso_secret";
        ssoSecretForAutheliaKey = "starcommand/selfhost/auth/authelia/open-webui_sso_secret";
      })
    ];
  };
}
