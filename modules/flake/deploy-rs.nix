# deploy-rs integration
# Reads deployment config from host configurations and sets up deploy-rs
# SSH keys are stored in SOPS and decrypted on-demand
{
  inputs,
  lib,
  ...
}:
let
  # Helper to read deployment config from nixosConfigurations
  # SSH keys are now stored in SOPS, not as files
  getDeploymentConfig =
    hostName: hostConfig:
    let
      # Safely try to get deployment config, returning null on any error
      tryGetCfg = builtins.tryEval (hostConfig.config.deployment or { });
      cfg = if tryGetCfg.success then tryGetCfg.value else { };
      # Check if deployment is enabled AND ip is set (non-empty string)
      isDeployable = (cfg.enable or false) && (cfg.ip or "") != "";
    in
    if isDeployable then
      {
        inherit hostName;
        ip = cfg.ip;
        sshPort = cfg.sshPort or 22;
        sshUser = cfg.sshUser or "admin";
        # SSH key is in SOPS, will be decrypted on-demand
        # Public keys and known_hosts are still files
        hostKeyPub = "./hosts/${hostName}/host_key.pub";
        knownHostsPath = "./hosts/${hostName}/known_hosts";
      }
    else
      null;
in
{
  # Add deploy-rs to flake inputs
  flake-file.inputs.deploy-rs.url = "github:serokell/deploy-rs";

  perSystem =
    {
      self',
      inputs',
      pkgs,
      system,
      ...
    }:
    let
      # Wrapper script that decrypts SSH keys from SOPS before running deploy-rs
      deploy-rs-with-sops = pkgs.writeShellApplication {
        name = "deploy-rs-with-sops";
        runtimeInputs = [
          inputs'.deploy-rs.packages.deploy-rs
          pkgs.sops
          pkgs.coreutils
        ];
        text = ''
          set -e

          # Decrypt SSH key from SOPS for the specified host.
          # Secrets live in the private nix-secrets checkout (default ~/nix-secrets,
          # override with NIX_SECRETS_DIR).
          decrypt_ssh_key() {
            local hostname="$1"
            local secrets_dir="''${NIX_SECRETS_DIR:-$HOME/nix-secrets}"
            local secrets_file="$secrets_dir/sops/hosts/$hostname.yaml"
            local sops_config="$secrets_dir/.sops.yaml"
            local temp_key="/tmp/ssh-key-$hostname-$$"

            if [ ! -f "$secrets_file" ]; then
              echo "Error: secrets file not found: $secrets_file" >&2
              echo "Clone codeberg.org/codywright/nix-secrets to ~/nix-secrets or set NIX_SECRETS_DIR." >&2
              exit 1
            fi

            # Decrypt the SSH key from SOPS
            # The key should be stored at <hostname>.system.sshPrivateKey
            SOPS_AGE_KEY_FILE="''${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}" \
              sops --config "$sops_config" \
              --decrypt --extract "['$hostname']['system']['sshPrivateKey']" \
              "$secrets_file" > "$temp_key"

            # Set proper permissions
            chmod 600 "$temp_key"

            echo "$temp_key"
          }

          # Parse deploy-rs arguments to find hostname
          HOSTNAME=""
          ARGS=()
          while [ $# -gt 0 ]; do
            case "$1" in
              -s|--switch)
                HOSTNAME="$2"
                ARGS+=("$1" "$2")
                shift 2
                ;;
              *)
                ARGS+=("$1")
                shift
                ;;
            esac
          done

          # If hostname specified, decrypt SSH key and build the full
          # --ssh-opts string. The previous wiring relied on
          # builtins.getEnv "DEPLOY_SSH_KEY" inside deploy.nodes.sshOpts,
          # which is empty under flake pure-eval (the default), so the -i
          # flag never reached ssh in CI. Pass --ssh-opts directly instead;
          # deploy-rs's --ssh-opts replaces the per-node sshOpts, so we
          # restate every flag we care about (identities, port, timeout,
          # known hosts).
          SSH_OPTS_FROM_SOPS=""
          if [ -n "$HOSTNAME" ]; then
            TEMP_KEY=$(decrypt_ssh_key "$HOSTNAME")
            trap "rm -f $TEMP_KEY" EXIT

            export DEPLOY_SSH_KEY="$TEMP_KEY"
            KNOWN_HOSTS_FILE="hosts/$HOSTNAME/known_hosts"
            if [ -n "''${FLEET_REPO_ROOT:-}" ] && [ -f "$FLEET_REPO_ROOT/$KNOWN_HOSTS_FILE" ]; then
              KNOWN_HOSTS_FILE="$FLEET_REPO_ROOT/$KNOWN_HOSTS_FILE"
            fi
            SSH_OPTS_FROM_SOPS="-i $TEMP_KEY -o IdentitiesOnly=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new"
            if [ -f "$KNOWN_HOSTS_FILE" ]; then
              SSH_OPTS_FROM_SOPS="$SSH_OPTS_FROM_SOPS -o UserKnownHostsFile=$KNOWN_HOSTS_FILE"
            fi
          fi

          # Run deploy-rs with original arguments
          if [ -n "$SSH_OPTS_FROM_SOPS" ]; then
            exec deploy-rs --ssh-opts "$SSH_OPTS_FROM_SOPS" "''${ARGS[@]}"
          else
            exec deploy-rs "''${ARGS[@]}"
          fi
        '';
      };
    in
    {
      apps = {
        deploy-rs = {
          type = "app";
          program = "${deploy-rs-with-sops}/bin/deploy-rs-with-sops";
        };
      };
    };

  # Define deploy-rs flake outputs
  flake =
    let
      # Get nixosConfigurations from the flake
      nixosConfigs = inputs.self.nixosConfigurations or { };

      # Collect all hosts with deployment enabled
      deploymentHosts = lib.filterAttrs (_: v: v != null) (lib.mapAttrs getDeploymentConfig nixosConfigs);
    in
    {
      # Define deploy-rs nodes from host configurations
      deploy.nodes = lib.mapAttrs (
        hostName: cfg:
        let
          # Get the nixosConfiguration for this host
          nixosConfig = nixosConfigs.${hostName};

          # Determine system from the nixosConfig
          targetSystem = nixosConfig.pkgs.stdenv.hostPlatform.system;

          # Use deploy-rs lib directly from the input
          deployLib = inputs.deploy-rs.lib.${targetSystem};
        in
        {
          hostname = cfg.ip;
          sshUser = cfg.sshUser;
          sshOpts = [
            "-o"
            "IdentitiesOnly=yes"
            "-o"
            "ConnectTimeout=10"
            "-p"
            (toString cfg.sshPort)
          ]
          ++ lib.optionals (builtins.getEnv "DEPLOY_SSH_KEY" != "") [
            "-i"
            (builtins.getEnv "DEPLOY_SSH_KEY")
          ]
          ++ lib.optionals (cfg.knownHostsPath != null) [
            "-o"
            "UserKnownHostsFile=${cfg.knownHostsPath}"
          ];
          profiles = {
            system = {
              user = "root";
              path = deployLib.activate.nixos nixosConfig;
            };
          };
        }
      ) deploymentHosts;

      # Deploy checks
      checks = builtins.mapAttrs (
        system: deployLib: deployLib.deployChecks inputs.self.deploy
      ) inputs.deploy-rs.lib;
    };
}
