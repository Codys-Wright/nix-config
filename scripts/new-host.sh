#!/usr/bin/env bash
# Generate a new host with SSH keys and secrets.yaml
# Usage: scripts/new-host.sh <hostname>

set -e

# Source helper functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"
source "$SCRIPT_DIR/sops-helpers.sh"

if [ -z "$1" ]; then
    red "Usage: $0 <hostname>"
    exit 1
fi

HOSTNAME="$1"

# Validate hostname
if ! validate_hostname "$HOSTNAME"; then
    exit 1
fi

HOST_DIR="hosts/$HOSTNAME"
cd "$FLAKE_ROOT"

# Check if host directory exists
if [ -d "$HOST_DIR" ]; then
    blue "Host directory '$HOST_DIR' already exists, checking for missing files..."
else
    blue "Creating new host: $HOSTNAME"
    ensure_dir "$HOST_DIR"
fi

# Generate host key pair (for server identity, SOPS encryption, known_hosts)
if [ ! -f "$HOST_DIR/host_key" ] || [ ! -f "$HOST_DIR/host_key.pub" ]; then
    blue "Generating host key pair..."
    ssh-keygen -t ed25519 -N "" -f "$HOST_DIR/host_key" -C "$HOSTNAME-host"
    chmod 600 "$HOST_DIR/host_key"
    green "Generated host key pair"
else
    blue "Host key pair already exists, skipping generation"
fi

# Generate deployment SSH key pair (for connecting to the server)
# We need to generate the key if either ssh.pub doesn't exist OR secrets.yaml doesn't exist
if [ ! -f "$HOST_DIR/ssh.pub" ] || [ ! -f "$HOST_DIR/secrets.yaml" ]; then
    blue "Generating deployment SSH key pair..."
    # Generate to a temp file first, then read it
    TEMP_SSH_KEY=$(mktemp)
    add_cleanup "rm -f $TEMP_SSH_KEY $TEMP_SSH_KEY.pub"
    ssh-keygen -t ed25519 -N "" -f "$TEMP_SSH_KEY" -C "$HOSTNAME-deploy"
    chmod 600 "$TEMP_SSH_KEY"

    # Read the deployment SSH private key for secrets.yaml
    SSH_PRIVATE_KEY=$(cat "$TEMP_SSH_KEY")
    SSH_PUBLIC_KEY=$(cat "$TEMP_SSH_KEY.pub")

    # Save the public key (we need this for authorized_keys)
    echo "$SSH_PUBLIC_KEY" > "$HOST_DIR/ssh.pub"

    # Clean up temp private key (we don't want it on disk, only in SOPS)
    rm -f "$TEMP_SSH_KEY" "$TEMP_SSH_KEY.pub"
    green "Generated deployment SSH key pair"
    
    # Store the private key for secrets.yaml creation
    DEPLOYMENT_KEY_AVAILABLE=true
else
    blue "Deployment SSH public key already exists, skipping generation"
    DEPLOYMENT_KEY_AVAILABLE=false
fi

# Create secrets.yaml with the private key embedded (plain text first)
if [ ! -f "$HOST_DIR/secrets.yaml" ]; then
    if [ "$DEPLOYMENT_KEY_AVAILABLE" = true ]; then
        blue "Creating secrets.yaml..."
        cat > "$HOST_DIR/secrets.yaml" <<EOF
$HOSTNAME:
  system:
    sshPrivateKey: |
$(echo "$SSH_PRIVATE_KEY" | sed 's/^/      /')
EOF
        green "Created secrets.yaml"
    else
        yellow "Cannot create secrets.yaml - deployment SSH key not available"
        yellow "Please generate the deployment key first or create secrets.yaml manually"
    fi
else
    blue "secrets.yaml already exists, skipping creation"
fi

# Convert host key to age key and add to sops.yaml (so host can decrypt its secrets)
# Check if host key is already in sops.yaml
if nix_develop yq-go eval ".keys[] | select(anchor == \"$HOSTNAME\")" "$SOPS_FILE" >/dev/null 2>&1; then
    blue "Host age key already exists in sops.yaml, skipping"
    HOST_AGE_KEY=$(nix_develop ssh-to-age < "$HOST_DIR/host_key.pub")
else
    blue "Adding host age key to sops.yaml..."
    HOST_AGE_KEY=$(nix_develop ssh-to-age < "$HOST_DIR/host_key.pub")

    if [ -z "$HOST_AGE_KEY" ] || [[ ! "$HOST_AGE_KEY" =~ ^age1 ]]; then
        yellow "Failed to convert host key to age key"
        yellow "You may need to add the host key to sops.yaml manually"
        HOST_AGE_KEY=""
    else
        # Add the host key to sops.yaml
        if ! sops_add_host_key "$HOSTNAME" "$HOST_AGE_KEY"; then
            yellow "Failed to automatically add host key to sops.yaml"
            yellow "  Host age key: $HOST_AGE_KEY"
        fi
    fi
fi

# Encrypt the secrets.yaml file immediately
# Only encrypt if the host key was successfully added to sops.yaml
if [ -n "$HOST_AGE_KEY" ]; then
    blue "Encrypting secrets.yaml with SOPS..."
    if [ -z "$SOPS_AGE_KEY_FILE" ]; then
        SOPS_AGE_KEY_FILE="sops.key"
    fi

    if [ ! -f "$SOPS_AGE_KEY_FILE" ]; then
        yellow "SOPS key file '$SOPS_AGE_KEY_FILE' not found."
        yellow "You'll need to encrypt the secrets file manually:"
        yellow "  SOPS_AGE_KEY_FILE=$SOPS_AGE_KEY_FILE nix develop --command sops --config sops.yaml -i $HOST_DIR/secrets.yaml"
    else
        # Encrypt the file (this will create SOPS metadata)
        if SOPS_AGE_KEY_FILE="$SOPS_AGE_KEY_FILE" nix_develop sops --config sops.yaml -e -i "$HOST_DIR/secrets.yaml" 2>&1; then
            green "secrets.yaml encrypted successfully"
        else
            yellow "Failed to encrypt secrets.yaml. You may need to encrypt it manually:"
            yellow "  SOPS_AGE_KEY_FILE=$SOPS_AGE_KEY_FILE nix develop --command sops --config sops.yaml -e -i $HOST_DIR/secrets.yaml"
        fi
    fi
else
    yellow "Skipping encryption - host key was not added to sops.yaml"
    yellow "Please add the host key to sops.yaml manually, then encrypt:"
    yellow "  SOPS_AGE_KEY_FILE=sops.key nix develop --command sops --config sops.yaml -e -i $HOST_DIR/secrets.yaml"
fi

# Create basic host configuration file if it doesn't exist
if [ ! -f "$HOST_DIR/$HOSTNAME.nix" ]; then
    blue "Creating host configuration file..."
    cat > "$HOST_DIR/$HOSTNAME.nix" <<EOF
{ inputs, den, pkgs, FTS, deployment, ... }:

{
  # Define the host
  den.hosts.x86_64-linux = {
    $HOSTNAME = {
      description = "$HOSTNAME host";
      aspect = "$HOSTNAME";
    };
  };

  # $HOSTNAME host-specific aspect
  den.aspects = {
    $HOSTNAME = {
      includes = [
        FTS.hardware
        deployment.default
      ];

      nixos = { config, lib, pkgs, ... }: {
        # Hardware detection is handled by FTS.hardware (includes FTS.hardware.facter)
        # Generate hardware config with: just generate-hardware $HOSTNAME
        # Then uncomment the line below to use it:
        # facter.reportPath = ./facter.json;

        deployment = {
          ip = "192.168.1.XXX";  # Update with your actual IP address
        };
      };
    };
  };
}
EOF
    green "Created host configuration file"
else
    blue "Host configuration file already exists, skipping creation"
fi

echo ""
green "Host '$HOSTNAME' created successfully!"
echo ""
blue "Generated files:"
echo "  - $HOST_DIR/host_key (host private key - for server identity, SOPS encryption)"
echo "  - $HOST_DIR/host_key.pub (host public key - for known_hosts)"
echo "  - $HOST_DIR/ssh.pub (deployment public key - for authorized_keys)"
echo "  - $HOST_DIR/secrets.yaml (encrypted secrets file with deployment SSH private key)"
echo "  - $HOST_DIR/$HOSTNAME.nix (host configuration)"
echo ""
yellow "Note: The deployment SSH private key is stored in secrets.yaml (encrypted), not as a separate file."
echo ""
blue "Next steps:"
echo "  1. Update the IP address in $HOST_DIR/$HOSTNAME.nix"
echo "  2. Generate hardware config: just generate-hardware $HOSTNAME"
echo "  3. Generate known_hosts: nix run .#gen-knownhosts-file \"$HOST_DIR/host_key.pub\" <ip> <port>"

