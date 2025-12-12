# Monitoring Service
# Grafana + Prometheus + Loki observability stack
{
  FTS,
  inputs,
  lib,
  ...
}: {
  FTS.selfhost._.monitoring = {
    domain,
    subdomain,
    adminPasswordKey,
    secretKeyKey,
    # LDAP configuration
    ldap ? {},
    # SSO configuration
    sso ? {},
    # Optional parameters
    ssl ? null,
    sslCertName ? domain, # Use domain as cert name (e.g., "starcommand.live")
    contactPoints ? [],
    ...
  } @ args: {
    class,
    aspect-chain,
  }: {
    description = ''
      Monitoring - Observability stack with Grafana, Prometheus, and Loki.

      Provides metrics collection, log aggregation, and visualization dashboards.
      Supports LDAP authentication and SSO integration.
    '';

    nixos = {
      config,
      lib,
      pkgs,
      ...
    }: let
      # Use provided ssl or fall back to reading from config
      sslCert =
        if ssl != null
        then ssl
        else config.shb.certs.certs.letsencrypt.${sslCertName};

      # Check if LDAP is configured
      ldapEnabled = ldap != {};

      # Check if SSO is configured
      ssoEnabled = sso != {} && sso ? enable && sso.enable;
    in {
      # Monitoring stack configuration
      shb.monitoring = {
        enable = true;
        inherit domain subdomain contactPoints;
        ssl = sslCert;

        # Admin credentials
        adminPassword.result = config.shb.sops.secret."${adminPasswordKey}".result;
        secretKey.result = config.shb.sops.secret."${secretKeyKey}".result;

        # LDAP integration (if configured)
        ldap = lib.mkIf ldapEnabled {
          userGroup = ldap.userGroup or "grafana_user";
          adminGroup = ldap.adminGroup or "grafana_admin";
        };

        # SSO integration (if configured)
        sso = lib.mkIf ssoEnabled {
          enable = true;
          authEndpoint = sso.authEndpoint;
          sharedSecret.result = config.shb.sops.secret."${sso.sharedSecretKey}".result;
          sharedSecretForAuthelia.result = config.shb.sops.secret."${sso.sharedSecretForAutheliaKey}".result;
        };
      };

      # SOPS secrets for monitoring
      shb.sops.secret."${adminPasswordKey}".request = config.shb.monitoring.adminPassword.request;
      shb.sops.secret."${secretKeyKey}".request = config.shb.monitoring.secretKey.request;

      # Ensure Grafana waits for Let's Encrypt certificate
      systemd.services.grafana = lib.mkIf (ssl != null || config.shb.certs.certs.letsencrypt != {}) {
        wants = [config.shb.certs.certs.letsencrypt.${sslCertName}.systemdService];
        after = [config.shb.certs.certs.letsencrypt.${sslCertName}.systemdService];
      };

      # NOTE: SSO secrets must be set up by the parent module
      # because they require settings.key overrides for secret sharing.
      # Parent should set up:
      #   - sso.sharedSecretKey for Grafana's OIDC secret
      #   - sso.sharedSecretForAutheliaKey with settings.key pointing to sharedSecretKey
    };
  };
}
