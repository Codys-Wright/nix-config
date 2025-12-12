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
    if yes_or_no "Host key pair already exists. Overwrite?"; then
        blue "Regenerating host key pair..."
        rm -f "$HOST_DIR/host_key" "$HOST_DIR/host_key.pub"
        ssh-keygen -t ed25519 -N "" -f "$HOST_DIR/host_key" -C "$HOSTNAME-host"
        chmod 600 "$HOST_DIR/host_key"
        green "Regenerated host key pair"
    else
        blue "Keeping existing host key pair"
    fi
fi

# Generate initrd SSH host key (for boot-time SSH access, encrypted disk unlocking)
if [ ! -f "$HOST_DIR/initrd_ssh_host_key" ] || [ ! -f "$HOST_DIR/initrd_ssh_host_key.pub" ]; then
    if yes_or_no "Generate initrd SSH host key for encrypted disk unlocking?"; then
        blue "Generating initrd SSH host key..."
        ssh-keygen -t ed25519 -N "" -f "$HOST_DIR/initrd_ssh_host_key" -C "$HOSTNAME-initrd"
        chmod 600 "$HOST_DIR/initrd_ssh_host_key"
        green "Generated initrd SSH host key"
        green "Boot SSH will be automatically enabled by FTS.deployment/bootssh"
    else
        blue "Skipping initrd SSH host key generation"
        yellow "Note: Boot SSH will not be available unless you generate this key later"
    fi
else
    blue "Initrd SSH host key already exists, skipping generation"
fi

# Generate deployment SSH key pair (for connecting to the server)
# We need to generate the key if either ssh.pub doesn't exist OR secrets.yaml doesn't exist
if [ ! -f "$HOST_DIR/ssh.pub" ] || [ ! -f "$HOST_DIR/secrets.yaml" ]; then
    if [ ! -f "$HOST_DIR/secrets.yaml" ] && [ -f "$HOST_DIR/ssh.pub" ]; then
        yellow "Warning: ssh.pub exists but secrets.yaml doesn't. Regenerating deployment key to create secrets.yaml..."
    else
        blue "Generating deployment SSH key pair..."
    fi
    
    # Generate to a temp file first, then read it
    TEMP_SSH_KEY=$(mktemp)
    add_cleanup "rm -f $TEMP_SSH_KEY $TEMP_SSH_KEY.pub"
    # Remove temp files if they exist to avoid prompts
    rm -f "$TEMP_SSH_KEY" "$TEMP_SSH_KEY.pub"
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
    blue "Deployment SSH public key and secrets.yaml already exist, skipping generation"
    DEPLOYMENT_KEY_AVAILABLE=false
fi

# Extract age key from host key for home-manager (if host_key exists)
AGE_KEY=""
if [ -f "$HOST_DIR/host_key" ]; then
    blue "Extracting age key from host_key for home-manager..."
    AGE_KEY=$(nix_develop ssh-to-age -private-key -i "$HOST_DIR/host_key" 2>&1)
    if [ -z "$AGE_KEY" ] || [[ ! "$AGE_KEY" =~ ^AGE-SECRET ]]; then
        yellow "Failed to extract age key from host_key"
        AGE_KEY=""
    fi
fi

# Create secrets.yaml from template
if [ ! -f "$HOST_DIR/secrets.yaml" ]; then
    if [ "$DEPLOYMENT_KEY_AVAILABLE" = true ]; then
        blue "Creating secrets.yaml from template..."
        
        # Copy template
        if [ ! -f "$FLAKE_ROOT/hosts/template/secrets-example.yaml" ]; then
            yellow "Warning: hosts/template/secrets-example.yaml not found, using minimal template"
            cat > "$HOST_DIR/secrets.yaml" <<EOF
$HOSTNAME:
  system:
    sshPrivateKey: |
$(echo "$SSH_PRIVATE_KEY" | sed 's/^/      /')
EOF
            if [ -n "$AGE_KEY" ]; then
                cat >> "$HOST_DIR/secrets.yaml" <<EOF
  keys:
    age: |
$(echo "$AGE_KEY" | sed 's/^/      /')
EOF
            fi
        else
            # Copy template and replace placeholders
            cp "$FLAKE_ROOT/hosts/template/secrets-example.yaml" "$HOST_DIR/secrets.yaml"
            
            # Replace hostname placeholder
            sed -i "s/<hostname>/$HOSTNAME/g" "$HOST_DIR/secrets.yaml"
            
            # Create temp files for multi-line replacements
            SSH_KEY_TEMP=$(mktemp)
            echo "$SSH_PRIVATE_KEY" | sed 's/^/      /' > "$SSH_KEY_TEMP"
            
            # Replace SSH private key placeholder
            # This is a bit tricky with multi-line replacements, so we'll use perl
            perl -i -pe "BEGIN{undef $/;} s/      -----BEGIN OPENSSH PRIVATE KEY-----\n      <WILL_BE_FILLED_BY_SCRIPT>\n      -----END OPENSSH PRIVATE KEY-----/$(cat $SSH_KEY_TEMP | sed 's/\//\\\//g' | sed ':a;N;$!ba;s/\n/\\n/g')/smg" "$HOST_DIR/secrets.yaml" 2>/dev/null || {
                # Fallback: just append the key if perl replacement fails
                yellow "Using fallback method for SSH key insertion"
                sed -i '/sshPrivateKey:/,/-----END OPENSSH PRIVATE KEY-----/d' "$HOST_DIR/secrets.yaml"
                cat >> "$HOST_DIR/secrets.yaml" <<EOF
    sshPrivateKey: |
$(echo "$SSH_PRIVATE_KEY" | sed 's/^/      /')
EOF
            }
            
            rm -f "$SSH_KEY_TEMP"
            
            # Replace age key placeholder if available
            if [ -n "$AGE_KEY" ]; then
                sed -i "s|<WILL_BE_FILLED_BY_SCRIPT>|$AGE_KEY|g" "$HOST_DIR/secrets.yaml"
            fi
        fi
        
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
EXISTING_KEY=$(nix_develop yq eval ".keys[] | select(anchor == \"$HOSTNAME\")" "$SOPS_FILE" 2>/dev/null || true)
if [ -n "$EXISTING_KEY" ]; then
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
{
  inputs,
  den,
  pkgs,
  FTS,
  __findFile,
  ...
}:
{
  # Define the host
  den.hosts.x86_64-linux = {
    $HOSTNAME = {
      description = "$HOSTNAME host";
      users.admin = { };  # Add users as needed
      aspect = "$HOSTNAME";
    };
  };

  # $HOSTNAME host-specific aspect
  den.aspects = {
    $HOSTNAME = {
      includes = [
        # Hardware and kernel
        <FTS.hardware>
        <FTS.kernel>
        
        # Deployment (SSH, networking, secrets, VM/ISO generation)
        <FTS.deployment>
        
        # Disk configuration (uncomment and configure as needed)
        # (<FTS.system/disk> {
        #   type = "btrfs-impermanence";
        #   device = "/dev/nvme0n1";
        #   withSwap = true;
        #   swapSize = "32";
        # })
        
        # Optional: Desktop environment
        # (FTS.desktop {
        #   environment.default = "gnome";
        #   displayManager.auto = true;
        # })
      ];

      nixos = { config, lib, pkgs, ... }: {
        # Hardware detection is handled by FTS.hardware (includes FTS.hardware.facter)
        # Generate hardware config with: just generate-hardware $HOSTNAME
        # The facter report path is auto-derived as hosts/$HOSTNAME/facter.json

        # Optional: Configure static network
        # deployment.staticNetwork = {
        #   ip = "192.168.1.XXX";
        #   gateway = "192.168.1.1";
        #   device = "en*";
        # };
        
        # Optional: Enable boot SSH for remote unlocking (if encrypted disk)
        # Requires: hosts/$HOSTNAME/initrd_ssh_host_key
        # deployment.bootssh.enable = true;
        
        # Optional: Enable WiFi hotspot for bootstrap
        # deployment.hotspot.enable = true;
      };
    };
  };
}
EOF
    green "Created host configuration file"
else
    if yes_or_no "Host configuration file already exists. Overwrite?"; then
        blue "Overwriting host configuration file..."
        cat > "$HOST_DIR/$HOSTNAME.nix" <<EOF
{
  inputs,
  den,
  pkgs,
  FTS,
  __findFile,
  ...
}:
{
  # Define the host
  den.hosts.x86_64-linux = {
    $HOSTNAME = {
      description = "$HOSTNAME host";
      users.admin = { };  # Add users as needed
      aspect = "$HOSTNAME";
    };
  };

  # $HOSTNAME host-specific aspect
  den.aspects = {
    $HOSTNAME = {
      includes = [
        # Hardware and kernel
        <FTS.hardware>
        <FTS.kernel>
        
        # Deployment (SSH, networking, secrets, VM/ISO generation)
        <FTS.deployment>
        
        # Disk configuration (uncomment and configure as needed)
        # (<FTS.system/disk> {
        #   type = "btrfs-impermanence";
        #   device = "/dev/nvme0n1";
        #   withSwap = true;
        #   swapSize = "32";
        # })
        
        # Optional: Desktop environment
        # (FTS.desktop {
        #   environment.default = "gnome";
        #   displayManager.auto = true;
        # })
      ];

      nixos = { config, lib, pkgs, ... }: {
        # Hardware detection is handled by FTS.hardware (includes FTS.hardware.facter)
        # Generate hardware config with: just generate-hardware $HOSTNAME
        # The facter report path is auto-derived as hosts/$HOSTNAME/facter.json

        # Optional: Configure static network
        # deployment.staticNetwork = {
        #   ip = "192.168.1.XXX";
        #   gateway = "192.168.1.1";
        #   device = "en*";
        # };
        
        # Optional: Enable boot SSH for remote unlocking (if encrypted disk)
        # Requires: hosts/$HOSTNAME/initrd_ssh_host_key
        # deployment.bootssh.enable = true;
        
        # Optional: Enable WiFi hotspot for bootstrap
        # deployment.hotspot.enable = true;
      };
    };
  };
}
EOF
        green "Overwritten host configuration file"
    else
        blue "Keeping existing host configuration file"
    fi
fi

echo ""
green "Host '$HOSTNAME' created successfully!"
echo ""
blue "Generated files:"
echo "  - $HOST_DIR/host_key (host private key - for server identity, SOPS encryption)"
echo "  - $HOST_DIR/host_key.pub (host public key - for known_hosts)"
if [ -f "$HOST_DIR/initrd_ssh_host_key" ]; then
echo "  - $HOST_DIR/initrd_ssh_host_key (initrd SSH host key - for boot-time SSH access)"
echo "  - $HOST_DIR/initrd_ssh_host_key.pub (initrd SSH public key)"
fi
echo "  - $HOST_DIR/ssh.pub (deployment public key - for authorized_keys)"
echo "  - $HOST_DIR/secrets.yaml (encrypted secrets file with deployment SSH private key)"
echo "  - $HOST_DIR/$HOSTNAME.nix (host configuration)"
echo ""
yellow "Note: The deployment SSH private key is stored in secrets.yaml (encrypted), not as a separate file."
echo ""
blue "Next steps:"
echo "  1. Generate hardware config: just generate-hardware $HOSTNAME"
echo "  2. Configure your host in $HOST_DIR/$HOSTNAME.nix:"
echo "     - Uncomment and configure disk setup (FTS.system/disk)"
echo "     - Add desktop environment if needed (FTS.desktop)"
echo "     - Configure static network if needed (deployment.staticNetwork)"
if [ -f "$HOST_DIR/initrd_ssh_host_key" ]; then
echo "     - Boot SSH is automatically enabled (initrd key detected)"
else
echo "     - (Optional) Generate initrd SSH key later for boot-time access:"
echo "       ssh-keygen -t ed25519 -N \"\" -f $HOST_DIR/initrd_ssh_host_key"
fi
echo "  3. Build and deploy: just build $HOSTNAME"

