# User secrets module
# Declares SOPS secrets and sets corresponding environment variables
{
  lib,
  FTS,
  ...
}:
{
  FTS.user-secrets = {
    description = "User secrets from SOPS with environment variables";

    homeManager = { config, ... }:
    {
      # Declare the personal_email secret
      # The key points to "{username}.personal_email" in the user's secrets.yaml
      # Using '/' to access nested YAML keys: cody.personal_email -> cody/personal_email
      sops.secrets."personal_email" = {
        key = "${config.home.username}/personal_email";
        # Ensure the secret is decrypted to a file we can read
        # The default path will be ~/.config/sops-nix/secrets/personal_email
      };

      # Set PERSONAL_EMAIL environment variable from the secret
      home.sessionVariables = {
        PERSONAL_EMAIL = lib.mkIf (config ? sops && config.sops ? secrets && config.sops.secrets ? "personal_email") (
          builtins.readFile config.sops.secrets."personal_email".path
        );
      };
    };
  };
}

