# Home-Assistant Service
# Home automation platform
{
  FTS,
  inputs,
  lib,
  ...
}:
{
  FTS.selfhost._.home-assistant =
    {
      domain,
      subdomain,
      # Required config
      name,
      country,
      latitude,
      longitude,
      time_zone,
      unit_system ? "metric",
      # Optional parameters
      ssl ? null,
      sslCertName ? domain,
      # LDAP integration
      ldap ? null,
      # Voice services
      voice ? null,
      # Config as secrets (for privacy)
      configSecrets ? null,
      ...
    }@args:
    {
      class,
      aspect-chain,
    }:
    {
      description = ''
        Home-Assistant - Home automation platform.

        Features:
        - Device integration and control
        - Automation and scenes
        - Energy monitoring
        - Voice assistants
        - LDAP integration

        Access at https://${subdomain}.${domain}
      '';

      nixos =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          fqdn = "${subdomain}.${domain}";
          sslCert = if ssl != null then ssl else config.shb.certs.certs.letsencrypt.${sslCertName};

          # Build config, optionally using secrets for sensitive values
          mkConfigValue =
            key: value:
            if configSecrets != null && configSecrets ? ${key} then
              { source = config.shb.sops.secret."${configSecrets.${key}}".result.path; }
            else
              value;
        in
        {
          # Home-Assistant configuration
          shb.home-assistant = {
            enable = true;
            inherit domain subdomain;
            ssl = sslCert;

            # Instance configuration
            config = {
              name = mkConfigValue "name" name;
              country = mkConfigValue "country" country;
              latitude = mkConfigValue "latitude" latitude;
              longitude = mkConfigValue "longitude" longitude;
              time_zone = mkConfigValue "time_zone" time_zone;
              inherit unit_system;
            };

            # LDAP configuration
            ldap = lib.mkIf (ldap != null) {
              enable = true;
              host = ldap.host or "127.0.0.1";
              port = ldap.port or 3890;
              userGroup = ldap.userGroup or "homeassistant_user";
              keepDefaultAuth = ldap.keepDefaultAuth or false;
            };

            # Voice services
            voice = lib.mkIf (voice != null) voice;
          };
        };
    };
}
