# User-specific SOPS secrets for home-manager
# Separates user secrets from host/service secrets
{
  inputs,
  lib,
  FTS,
  ...
}:
{
  FTS.user-secrets = {
    description = "User-level SOPS secrets management (for home-manager)";

    homeManager =
      { config, ... }:
      let
        homeDirectory = config.home.homeDirectory;
        username = config.home.username;

        # Path to user-specific secrets file
        userSecretsPath = ../../users/${username}/secrets.yaml;
        
        # Check if the secrets file exists
        secretsFileExists = builtins.pathExists userSecretsPath;
      in
      lib.mkIf secretsFileExists {
        # Import SOPS home-manager module
        imports = [ inputs.sops-nix.homeManagerModules.sops ];

        sops = {
          # Use the age key extracted by the host-level SOPS module
          age.keyFile = "${homeDirectory}/.config/sops/age/keys.txt";

          # User-specific secrets file
          defaultSopsFile = userSecretsPath;
          validateSopsFiles = true;

          # Secrets should be declared in modules that use them
          secrets = { };
        };
      };
  };
}
