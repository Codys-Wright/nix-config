# Host-level secrets via sops-nix, sourced from the private nix-secrets input.
# Looks for "${inputs.nix-secrets}/sops/hosts/<hostname>.yaml".
{
  inputs,
  fleet,
  ...
}:
{
  fleet.deployment._.secrets = {
    description = ''
      Secrets management using sops-nix.

      Decrypts "''${inputs.nix-secrets}/sops/hosts/<hostname>.yaml" with the
      host's SSH ed25519 key (ssh-to-age). Also bootstraps the primary user's
      age key (secret "keys/age") into ~/.config/sops/age/keys.txt so
      home-manager sops works without manual key copying.
    '';

    # Import sops-nix module
    includes = [
      { nixos.imports = [ inputs.sops-nix.nixosModules.sops ]; }
      # Bootstrap the age key for this host's users (host context needed)
      (
        { host, ... }:
        {
          nixos =
            { config, lib, ... }:
            let
              users = builtins.attrNames host.users;
            in
            lib.mkIf (config.deployment.enable && config.deployment.secrets.enable && users != [ ]) {
              sops.secrets = builtins.listToAttrs (
                map (user: {
                  name = "keys/age";
                  value = {
                    owner = user;
                    path = "${config.users.users.${user}.home}/.config/sops/age/keys.txt";
                  };
                }) (lib.take 1 users)
              );
            };
        }
      )
    ];

    nixos =
      {
        config,
        lib,
        ...
      }:
      let
        hostname = config.networking.hostName or "nixos";
        secretsYamlPath = "${inputs.nix-secrets}/sops/hosts/${hostname}.yaml";
        hasSecretsFile = builtins.pathExists secretsYamlPath;
      in
      {
        options.deployment.secrets = {
          enable = lib.mkEnableOption "secrets management" // {
            default = hasSecretsFile;
          };
        };

        config = lib.mkIf (config.deployment.enable && config.deployment.secrets.enable) {
          sops = {
            defaultSopsFile = secretsYamlPath;
            # Mandatory: the file lives in the nix store (flake input), which
            # sops-nix cannot validate at evaluation time.
            validateSopsFiles = false;

            age = {
              # The host decrypts with its own SSH host key (ssh-to-age).
              # Enroll new hosts with `just add-host <name> <ip>` in nix-secrets.
              sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
              keyFile = "/var/lib/sops-nix/key.txt";
              generateKey = true;
            };

            secrets = lib.mkDefault { };
          };
        };
      };
  };
}
