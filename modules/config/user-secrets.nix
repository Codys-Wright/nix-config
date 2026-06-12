# User-specific SOPS secrets for home-manager
# Separates user secrets from host/service secrets
{
  inputs,
  lib,
  fleet,
  ...
}:
{
  fleet.user-secrets = {
    description = "User-level SOPS secrets management (for home-manager)";

    homeManager =
      { config, ... }:
      let
        homeDirectory = config.home.homeDirectory;
        username = config.home.username;

        # Per-user secrets file in the private nix-secrets input
        userSecretsPath = "${inputs.nix-secrets}/sops/users/${username}.yaml";

        # Check if the secrets file exists
        secretsFileExists = builtins.pathExists userSecretsPath;
      in
      {
        # Import SOPS home-manager module unconditionally — `imports` inside
        # lib.mkIf is silently ignored by the module system, leaving the
        # `sops` option undefined.
        imports = [ inputs.sops-nix.homeManagerModules.sops ];

        config = lib.mkIf secretsFileExists {
          sops = {
            # Use the age key extracted by the host-level SOPS module
            age.keyFile = "${homeDirectory}/.config/sops/age/keys.txt";

            # User-specific secrets file (store path from the input — sops-nix
            # cannot validate non-local paths at eval time)
            defaultSopsFile = userSecretsPath;
            validateSopsFiles = false;

            # Secrets should be declared in modules that use them
            secrets = { };
          };
        };
      };
  };
}
