# Karakeep Service
# LLM-powered bookmarking service
{
  FTS,
  inputs,
  lib,
  ...
}:
{
  FTS.selfhost._.karakeep =
    {
      domain,
      subdomain,
      # Required secrets
      nextauthSecretKey,
      meilisearchMasterKeyKey,
      # SSO integration (required)
      ssoSecretKey,
      ssoSecretForAutheliaKey,
      authEndpoint,
      # Optional parameters
      ssl ? null,
      sslCertName ? domain,
      port ? 3000,
      # LDAP integration
      ldapUserGroup ? "karakeep_user",
      ssoClientID ? "karakeep",
      # Ollama/LLM integration
      ollamaBaseUrl ? null,
      inferenceTextModel ? null,
      inferenceImageModel ? null,
      embeddingTextModel ? null,
      enableAutoSummarization ? false,
      # Extra environment variables
      extraEnvironment ? { },
      ...
    }@args:
    {
      class,
      aspect-chain,
    }:
    {
      description = ''
        Karakeep - LLM-powered bookmarking service.

        Features:
        - AI-powered bookmark organization
        - Full-text search with Meilisearch
        - LDAP/SSO integration
        - Ollama integration for local LLMs

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

          # Build environment variables for Ollama integration
          ollamaEnv =
            lib.optionalAttrs (ollamaBaseUrl != null) {
              OLLAMA_BASE_URL = ollamaBaseUrl;
            }
            // lib.optionalAttrs (inferenceTextModel != null) {
              INFERENCE_TEXT_MODEL = inferenceTextModel;
            }
            // lib.optionalAttrs (inferenceImageModel != null) {
              INFERENCE_IMAGE_MODEL = inferenceImageModel;
            }
            // lib.optionalAttrs (embeddingTextModel != null) {
              EMBEDDING_TEXT_MODEL = embeddingTextModel;
            }
            // lib.optionalAttrs enableAutoSummarization {
              INFERENCE_ENABLE_AUTO_SUMMARIZATION = "true";
            };
        in
        {
          # Karakeep configuration
          shb.karakeep = {
            enable = true;
            inherit domain subdomain port;
            ssl = sslCert;

            # Environment variables
            environment = ollamaEnv // extraEnvironment;

            # LDAP configuration
            ldap = {
              userGroup = ldapUserGroup;
            };

            # Secrets
            nextauthSecret.result = config.shb.sops.secret."${nextauthSecretKey}".result;
            meilisearchMasterKey.result = config.shb.sops.secret."${meilisearchMasterKeyKey}".result;

            # SSO configuration
            sso = {
              enable = true;
              authEndpoint = authEndpoint;
              clientID = ssoClientID;
              authorization_policy = "one_factor";
              sharedSecret.result = config.shb.sops.secret."${ssoSecretKey}".result;
              sharedSecretForAuthelia.result = config.shb.sops.secret."${ssoSecretForAutheliaKey}".result;
            };
          };

          # Note: SOPS secrets are defined in the parent selfhost.nix module
          # with proper ownership settings
        };
    };
}
