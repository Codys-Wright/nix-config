# SOPS secrets management module
# Handles both NixOS (host-level) and home-manager (user-level) SOPS configuration
# Based on emergent-config's sops.nix modules
{
  inputs,
  den,
  lib,
  FTS,
  ...
}:
{
  FTS.secrets = {
    description = "SOPS secrets management for hosts and users";

    # NixOS (host-level) SOPS configuration
    nixos = { config, pkgs, ... }:
    let
      # Auto-derive hostname from config (set by den)
      hostname = config.networking.hostName or "nixos";
      
      # Path to host-specific secrets file (relative to host file location)
      # Path is resolved relative to the host file: ../../hosts/<hostname>/secrets.yaml
      secretsYamlPath = ../../hosts/${hostname}/secrets.yaml;
      
      # Get primary username (first user or fallback)
      primaryUsername = let
        host = config._module.args.host or null;
        users = if host != null then (builtins.attrNames (host.users or {})) else [];
      in
        if users != [] then builtins.head users else "admin";
    in
    {
      # Import SOPS NixOS module
      imports = [
        inputs.sops-nix.nixosModules.default
      ];

      sops = {
        # Set default SOPS file to host-specific secrets
        defaultSopsFile = secretsYamlPath;
        validateSopsFiles = true;  # Validate SOPS files at evaluation time
        
        # Automatically import host SSH keys as age keys for SOPS decryption
        age = {
          sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        };
      };

      # Configure secrets that are needed for system setup
      # The deployment module will add its own secrets (like sshPrivateKey)
      sops.secrets = lib.mkMerge [
        {
          # Extract age key for home-manager to use
          # This key is stored in the host's secrets.yaml as "keys/age"
          # It allows home-manager secrets to work without manually copying the age key
          # The key will be extracted to ~/.config/sops/age/keys.txt
          "keys/age" = lib.mkIf (config ? home-manager && config.home-manager ? users && config.home-manager.users != {}) {
            owner = config.users.users.${primaryUsername}.name;
            group = config.users.users.${primaryUsername}.group;
            path = "${config.users.users.${primaryUsername}.home}/.config/sops/age/keys.txt";
          };
        }
      ];

      # The containing folders are created as root and if this is the first ~/.config/ entry,
      # the ownership is busted and home-manager can't target because it can't write into .config...
      # This ensures the age key directory has correct permissions for home-manager
      system.activationScripts.sopsSetAgeKeyOwnership = lib.mkIf (config ? home-manager && config.home-manager ? users && config.home-manager.users != {}) (
        let
          ageFolder = "${config.users.users.${primaryUsername}.home}/.config/sops/age";
          user = config.users.users.${primaryUsername}.name;
          group = config.users.users.${primaryUsername}.group;
        in
        ''
          mkdir -p ${ageFolder} || true
          chown -R ${user}:${group} ${config.users.users.${primaryUsername}.home}/.config
        ''
      );
    };

    # home-manager (user-level) SOPS configuration
    homeManager = { config, ... }:
    let
      homeDirectory = config.home.homeDirectory;
      
      # Path to user-specific secrets file (relative to module location)
      # Path is resolved relative to the module: ../../users/<username>/secrets.yaml
      userSecretsPath = ../../users/${config.home.username}/secrets.yaml;
    in
    {
      # Import SOPS home-manager module
      imports = [
        inputs.sops-nix.homeManagerModules.sops
      ];

      sops = {
        # Use the age key extracted by the host-level SOPS module
        # The age key is extracted from the host's SSH key via activation script
        # This allows home-manager to decrypt user secrets using the host's SSH-derived age key
        age.keyFile = "${homeDirectory}/.config/sops/age/keys.txt";
        
        # Default to user-specific secrets file
        defaultSopsFile = userSecretsPath;
        validateSopsFiles = true;  # Validate SOPS files at evaluation time
        
        # Secrets should be declared in the modules that use them
        # Example: In a module that needs personal_email, declare:
        #   sops.secrets."personal_email" = {
        #     key = "${config.home.username}/personal_email";
        #   };
        # Then access it via: config.sops.secrets."personal_email".path
        # Or use placeholder: config.sops.placeholder."personal_email"
        # The sops-nix module will automatically create a systemd user service
        # that runs on login to decrypt secrets when secrets are declared
        # The service is created automatically by sops-nix when cfg.secrets != {}
        secrets = { };
      };
      
      # Note: The sops-nix module automatically creates systemd.user.services.sops-nix
      # when secrets are declared. The service is configured to start on login
      # via WantedBy = [ "default.target" ] (or graphical-session-pre.target for GPG)
    };
  };
}

