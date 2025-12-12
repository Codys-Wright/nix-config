# Secrets management module using sops-nix
# Automatically finds secrets.yaml in hosts/<hostname>/
{
  inputs,
  den,
  lib,
  FTS,
  ...
}:
{
  FTS.deployment._.secrets = {
    description = ''
      Secrets management using sops-nix.
      
      Automatically looks for hosts/<hostname>/secrets.yaml and ssh keys.
    '';

    # Import sops-nix module
    includes = [
      { nixos.imports = [ inputs.sops-nix.nixosModules.sops ]; }
    ];

    nixos = { config, pkgs, lib, ... }:
    let
      hostname = config.networking.hostName or "nixos";
      secretsYamlPath = ../../hosts/${hostname}/secrets.yaml;
      sshKeyPath = ../../hosts/${hostname}/ssh;
      
      # Check if files exist
      secretsFileExists = builtins.tryEval (builtins.pathExists secretsYamlPath);
      sshKeyExists = builtins.tryEval (builtins.pathExists sshKeyPath);
      hasSecretsFile = secretsFileExists.success && secretsFileExists.value;
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
          
          age = {
            sshKeyPaths = lib.mkIf (sshKeyExists.success && sshKeyExists.value) [ sshKeyPath ];
            keyFile = "/var/lib/sops-nix/key.txt";
            generateKey = true;
          };

          secrets = lib.mkDefault {};
        };
      };
    };
  };
}
