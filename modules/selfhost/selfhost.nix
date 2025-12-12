# Self-hosting services coordination module using SelfHostBlocks
{
  inputs,
  lib,
  FTS,
  den,
  ...
}:
{
  FTS.selfhost = {
    description = ''
      Self-hosting services stack using SelfHostBlocks.
      
      Provides complete self-hosted infrastructure including:
      - Authentication (LLDAP, Authelia SSO)
      - Applications (Nextcloud with LDAP & SSO)
      - SSL/TLS certificates (self-signed CA)
      - Local DNS resolution (dnsmasq)
      
      Note: Automatically configures hosts to use selfhostblocks' patched nixpkgs.
      This provides patched LLDAP options and other enhancements.
      
      Secrets managed via users/starcommand/secrets.yaml
    '';

    # Make this a parametric aspect (even if we don't use parameters yet)
    __functor = _: args: { class, aspect-chain, ... }@aspectArgs:
    let
      domain = "homelab.local";
      nextcloudSubdomain = "cloud";
      ldapSubdomain = "ldap";
      authSubdomain = "auth";
      
      # Extract host information from aspect-chain if available
      # This allows us to configure the host's instantiate function
      hostInfo = aspectArgs.host or null;
    in
    {
      # Note: Hosts that include this aspect should set:
      #   den.hosts.<system>.<hostname>.instantiate = 
      #     inputs.selfhostblocks.lib.<system>.patchedNixpkgs.nixosSystem;
      # This ensures the patched nixpkgs (with LLDAP enhancements) is used.

      nixos = { config, lib, pkgs, ... }: {
        # Import SelfHostBlocks modules
        # These use selfhostblocks' patched nixpkgs for enhanced options
        imports = [
          inputs.selfhostblocks.nixosModules.lldap
          inputs.selfhostblocks.nixosModules.sops
          inputs.selfhostblocks.nixosModules.authelia
          inputs.selfhostblocks.nixosModules.nextcloud-server
          inputs.selfhostblocks.nixosModules.nginx
          inputs.selfhostblocks.nixosModules.ssl
          inputs.sops-nix.nixosModules.default
        ];

        # SOPS configuration - points to starcommand user secrets
        sops.defaultSopsFile = lib.mkDefault ../../users/starcommand/secrets.yaml;

        # SSL certificates (self-signed CA)
        shb.certs = {
          cas.selfsigned.myca = {
            name = "Homelab CA";
          };
          certs.selfsigned.n = {
            ca = config.shb.certs.cas.selfsigned.myca;
            domain = "*.${domain}";
            group = "nginx";
          };
        };

        # LLDAP - Lightweight LDAP identity provider
        # This tests if we're using the patched nixpkgs (which adds the enforceGroups option)
        shb.lldap = {
          enable = true;
          inherit domain;
          subdomain = ldapSubdomain;
          ldapPort = 3890;
          webUIListenPort = 17170;
          dcdomain = "dc=${builtins.replaceStrings ["."] [",dc="] domain}";
          ssl = config.shb.certs.certs.selfsigned.n;
          # Generated with: openssl rand -base64 32
          ldapUserPassword.result = config.shb.sops.secret."starcommand/selfhost/auth/lldap/admin_password".result;
          # Generated with: openssl rand -base64 32
          jwtSecret.result = config.shb.sops.secret."starcommand/selfhost/auth/lldap/jwt_secret".result;
        };
        shb.sops.secret."starcommand/selfhost/auth/lldap/admin_password".request = config.shb.lldap.ldapUserPassword.request;
        shb.sops.secret."starcommand/selfhost/auth/lldap/jwt_secret".request = config.shb.lldap.jwtSecret.request;

        # Authelia - SSO/OIDC provider
        shb.authelia = {
          enable = true;
          inherit domain;
          subdomain = authSubdomain;
          ssl = config.shb.certs.certs.selfsigned.n;
          ldapPort = config.shb.lldap.ldapPort;
          ldapHostname = "127.0.0.1";
          dcdomain = config.shb.lldap.dcdomain;

          secrets = {
            # Generated with: openssl rand -base64 64
            jwtSecret.result = config.shb.sops.secret."starcommand/selfhost/auth/authelia/jwt_secret".result;
            # Reuse LLDAP admin password for LDAP connection
            ldapAdminPassword.result = config.shb.sops.secret."starcommand/selfhost/auth/authelia/ldap_admin_password".result;
            # Generated with: openssl rand -base64 64
            sessionSecret.result = config.shb.sops.secret."starcommand/selfhost/auth/authelia/session_secret".result;
            # Generated with: openssl rand -base64 64
            storageEncryptionKey.result = config.shb.sops.secret."starcommand/selfhost/auth/authelia/storage_encryption_key".result;
            # Generated with: openssl rand -base64 64
            identityProvidersOIDCHMACSecret.result = config.shb.sops.secret."starcommand/selfhost/auth/authelia/oidc_hmac_secret".result;
            # Generated with: openssl genrsa 4096
            identityProvidersOIDCIssuerPrivateKey.result = config.shb.sops.secret."starcommand/selfhost/auth/authelia/oidc_issuer_private_key".result;
          };
        };
        shb.sops.secret."starcommand/selfhost/auth/authelia/jwt_secret".request = config.shb.authelia.secrets.jwtSecret.request;
        shb.sops.secret."starcommand/selfhost/auth/authelia/ldap_admin_password" = {
          request = config.shb.authelia.secrets.ldapAdminPassword.request;
          settings.key = "starcommand/selfhost/auth/lldap/admin_password";  # Reuse LLDAP admin password
        };
        shb.sops.secret."starcommand/selfhost/auth/authelia/session_secret".request = config.shb.authelia.secrets.sessionSecret.request;
        shb.sops.secret."starcommand/selfhost/auth/authelia/storage_encryption_key".request = config.shb.authelia.secrets.storageEncryptionKey.request;
        shb.sops.secret."starcommand/selfhost/auth/authelia/oidc_hmac_secret".request = config.shb.authelia.secrets.identityProvidersOIDCHMACSecret.request;
        shb.sops.secret."starcommand/selfhost/auth/authelia/oidc_issuer_private_key".request = config.shb.authelia.secrets.identityProvidersOIDCIssuerPrivateKey.request;

        # Nextcloud with LDAP and SSO integration
        shb.nextcloud = {
          enable = true;
          inherit domain;
          subdomain = nextcloudSubdomain;
          dataDir = "/var/lib/nextcloud";
          port = lib.mkForce null;  # Use SSL
          ssl = config.shb.certs.certs.selfsigned.n;
          tracing = null;
          defaultPhoneRegion = "US";

          # Generated with: openssl rand -base64 32
          adminPass.result = config.shb.sops.secret."starcommand/selfhost/apps/nextcloud/admin_password".result;

          apps = {
            previewgenerator.enable = true;
            
            # LDAP integration
            ldap = {
              enable = true;
              host = "127.0.0.1";
              port = config.shb.lldap.ldapPort;
              dcdomain = config.shb.lldap.dcdomain;
              adminName = "admin";
              # Reuse LLDAP admin password
              adminPassword.result = config.shb.sops.secret."starcommand/selfhost/auth/lldap/admin_password".result;
              userGroup = "nextcloud_user";
            };
            
            # SSO integration via Authelia
            sso = {
              enable = true;
              endpoint = "https://${authSubdomain}.${domain}";
              clientID = "nextcloud";
              fallbackDefaultAuth = true;
              # Generated with: openssl rand -base64 32
              secret.result = config.shb.sops.secret."starcommand/selfhost/apps/nextcloud/sso_secret".result;
              # Shared secret between Nextcloud and Authelia
              secretForAuthelia.result = config.shb.sops.secret."starcommand/selfhost/apps/nextcloud/sso_secret".result;
            };
          };
        };
        shb.sops.secret."starcommand/selfhost/apps/nextcloud/admin_password".request = config.shb.nextcloud.adminPass.request;
        shb.sops.secret."starcommand/selfhost/apps/nextcloud/sso_secret".request = config.shb.nextcloud.apps.sso.secret.request;

        # Local DNS resolution for homelab services
        services.dnsmasq = {
          enable = true;
          settings = {
            domain-needed = true;
            bogus-priv = true;
            address = map (hostname: "/${hostname}/127.0.0.1") [
              domain
              "${nextcloudSubdomain}.${domain}"
              "${ldapSubdomain}.${domain}"
              "${authSubdomain}.${domain}"
            ];
          };
        };

        # Nginx configuration
        shb.nginx.accessLog = lib.mkDefault true;
        shb.nginx.debugLog = lib.mkDefault false;
      };
    };
  };
}
