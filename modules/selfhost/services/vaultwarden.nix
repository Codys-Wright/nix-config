# Vaultwarden Service
# Password manager (Bitwarden-compatible)
{
  FTS,
  inputs,
  lib,
  ...
}: {
  FTS.selfhost._.vaultwarden = {
    domain,
    subdomain,
    databasePasswordKey,
    # Optional parameters
    ssl ? null,
    sslCertName ? domain,  # Use domain as cert name (e.g., "starcommand.live")
    port ? 8222,
    authEndpoint ? null,
    smtp ? null,
    ...
  } @ args: {
    class,
    aspect-chain,
  }: {
    description = ''
      Vaultwarden - Bitwarden-compatible password manager.
      
      Provides secure password storage, sharing, and management.
      Supports SSO integration and email notifications.
      Admin panel is protected by SSO and requires vaultwarden_admin group.
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
    in {
      # Vaultwarden configuration
      shb.vaultwarden = {
        enable = true;
        inherit domain subdomain port;
        ssl = sslCert;
        
        # SSO integration (if configured)
        authEndpoint = authEndpoint;
        
        # Database password from secrets
        databasePassword.result = config.shb.sops.secret."${databasePasswordKey}".result;
        
        # SMTP configuration (if provided)
        smtp = if smtp != null then {
          inherit (smtp) from_address host port username;
          from_name = smtp.from_name or "Vaultwarden";
          security = smtp.security or "starttls";
          auth_mechanism = smtp.auth_mechanism or "Login";
          password.result = config.shb.sops.secret."${smtp.passwordKey}".result;
        } else null;
      };

      # SOPS secret for database password
      shb.sops.secret."${databasePasswordKey}".request = config.shb.vaultwarden.databasePassword.request;
      
      # SOPS secret for SMTP password (if SMTP is configured)
    }
    // (if smtp != null then {
      shb.sops.secret."${smtp.passwordKey}".request = config.shb.vaultwarden.smtp.password.request;
    } else {});
  };
}

