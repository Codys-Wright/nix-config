#!/usr/bin/env bash
# Generate a new user with age keys and secrets.yaml
# Usage: scripts/new-user.sh <username> [hostname]

set -e

# Source helper functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"
source "$SCRIPT_DIR/sops-helpers.sh"

if [ -z "$1" ]; then
    red "Usage: $0 <username> [hostname]"
    exit 1
fi

USERNAME="$1"
HOSTNAME="${2:-$HOSTNAME}"  # Optional: associate with a specific host

# Validate username
if ! validate_hostname "$USERNAME"; then
    red "Invalid username format"
    exit 1
fi

USER_DIR="users/$USERNAME"
cd "$FLAKE_ROOT"

# Check if user directory exists
if [ -d "$USER_DIR" ]; then
    blue "User directory '$USER_DIR' already exists, checking for missing files..."
else
    blue "Creating new user: $USERNAME"
    ensure_dir "$USER_DIR"
fi

# Generate age key for the user
AGE_KEY_FILE="$USER_DIR/age.key"
AGE_PUBLIC_KEY=""

if [ ! -f "$AGE_KEY_FILE" ]; then
    if yes_or_no "Generate age key for $USERNAME?"; then
        blue "Generating age key..."
        # Generate age key and capture output
        AGE_OUTPUT=$(nix_develop age-keygen 2>&1)
        
        # Parse the output - age-keygen outputs like:
        # # created: 2024-01-01T00:00:00Z
        # # public key: age1...
        # AGE-SECRET-KEY-1...
        AGE_SECRET=$(echo "$AGE_OUTPUT" | grep "^AGE-SECRET-KEY" | head -1)
        AGE_PUBLIC=$(echo "$AGE_OUTPUT" | grep "public key:" | cut -d: -f2- | xargs)
        
        if [ -z "$AGE_SECRET" ]; then
            red "Failed to generate age key - could not find secret key"
            yellow "age-keygen output:"
            echo "$AGE_OUTPUT"
            exit 1
        fi
        
        if [ -z "$AGE_PUBLIC" ]; then
            red "Failed to generate age key - could not find public key"
            yellow "age-keygen output:"
            echo "$AGE_OUTPUT"
            exit 1
        fi
        
        # Save the private key
        echo "$AGE_SECRET" > "$AGE_KEY_FILE"
        chmod 600 "$AGE_KEY_FILE"
        
        AGE_PUBLIC_KEY="$AGE_PUBLIC"
        green "Generated age key for $USERNAME"
        blue "Public key: $AGE_PUBLIC_KEY"
        blue "Private key saved to: $AGE_KEY_FILE"
    else
        blue "Skipping age key generation"
    fi
else
    blue "Age key already exists, extracting public key..."
    AGE_PUBLIC_KEY=$(nix_develop age-keygen -y "$AGE_KEY_FILE" 2>/dev/null | grep "^age1" | head -1)
    if [ -n "$AGE_PUBLIC_KEY" ]; then
        blue "Public key: $AGE_PUBLIC_KEY"
    else
        yellow "Failed to extract public key from existing age key"
    fi
fi

# Create secrets.yaml from template
if [ ! -f "$USER_DIR/secrets.yaml" ]; then
    blue "Creating secrets.yaml from template..."
    
    # Copy template
    if [ ! -f "$FLAKE_ROOT/users/template/secrets-example.yaml" ]; then
        yellow "Warning: users/template/secrets-example.yaml not found, using minimal template"
        cat > "$USER_DIR/secrets.yaml" <<EOF
$USERNAME:
  personal:
    email: "your.name@example.com"
  git:
    email: "your.name@example.com"
    username: "$USERNAME"
EOF
    else
        # Copy template and replace placeholders
        cp "$FLAKE_ROOT/users/template/secrets-example.yaml" "$USER_DIR/secrets.yaml"
        
        # Replace username placeholder
        sed -i "s/<username>/$USERNAME/g" "$USER_DIR/secrets.yaml"
    fi
    
    green "Created secrets.yaml"
    yellow "Please edit $USER_DIR/secrets.yaml to add your actual secrets"
else
    blue "secrets.yaml already exists, skipping creation"
fi

# Add user age key to sops.yaml (if we have one)
if [ -n "$AGE_PUBLIC_KEY" ]; then
    EXISTING_KEY=$(nix_develop yq eval ".keys[] | select(anchor == \"$USERNAME\")" "$SOPS_FILE" 2>/dev/null || true)
    if [ -n "$EXISTING_KEY" ]; then
        blue "User age key already exists in sops.yaml, skipping"
    else
        blue "Adding user age key to sops.yaml..."
        
        # Add the key to the keys section
        nix_develop yq eval -i ".keys += [\"$AGE_PUBLIC_KEY\"] | .keys[-1] anchor = \"$USERNAME\"" "$SOPS_FILE"
        green "Added user age key to sops.yaml"
        
        # Add creation rule for user secrets
        EXISTING_RULE=$(nix_develop yq eval ".creation_rules[] | select(.path_regex == \"^users/$USERNAME/secrets\\\\.yaml\$\")" "$SOPS_FILE" 2>/dev/null || true)
        if [ -z "$EXISTING_RULE" ]; then
            blue "Adding creation rule for $USERNAME secrets..."
            
            # Add creation rule with placeholder values, then convert to aliases
            u="\"$USERNAME\""
            m="\"me\""
            user_selector=".creation_rules[] | select(.path_regex == \"^users/$USERNAME/secrets\\\\.yaml\$\")"
            
            # First add the rule with placeholder string values
            nix_develop yq eval -i ".creation_rules += [{\"path_regex\": \"^users/$USERNAME/secrets\\\\.yaml$\", \"key_groups\": [{\"age\": [$m, $u]}]}]" "$SOPS_FILE"
            
            # Then convert those strings to YAML aliases/anchors using the 'alias' keyword
            nix_develop yq eval -i "($user_selector).key_groups[].age[0] alias = $m" "$SOPS_FILE"
            nix_develop yq eval -i "($user_selector).key_groups[].age[1] alias = $u" "$SOPS_FILE"
            
            green "Added creation rule for $USERNAME"
        else
            blue "Creation rule for $USERNAME already exists"
        fi
    fi
    
    # Encrypt the secrets.yaml file
    blue "Encrypting secrets.yaml with SOPS..."
    if [ -z "$SOPS_AGE_KEY_FILE" ]; then
        SOPS_AGE_KEY_FILE="sops.key"
    fi

    if [ ! -f "$SOPS_AGE_KEY_FILE" ]; then
        yellow "SOPS key file '$SOPS_AGE_KEY_FILE' not found."
        yellow "You'll need to encrypt the secrets file manually:"
        yellow "  SOPS_AGE_KEY_FILE=$SOPS_AGE_KEY_FILE nix develop --command sops --config sops.yaml -e -i $USER_DIR/secrets.yaml"
    else
        # Encrypt the file (this will create SOPS metadata)
        if SOPS_AGE_KEY_FILE="$SOPS_AGE_KEY_FILE" nix_develop sops --config sops.yaml -e -i "$USER_DIR/secrets.yaml" 2>&1; then
            green "secrets.yaml encrypted successfully"
        else
            yellow "Failed to encrypt secrets.yaml. You may need to encrypt it manually:"
            yellow "  SOPS_AGE_KEY_FILE=$SOPS_AGE_KEY_FILE nix develop --command sops --config sops.yaml -e -i $USER_DIR/secrets.yaml"
        fi
    fi
else
    yellow "No age key available, skipping sops.yaml and encryption"
fi

# Create basic user configuration file if it doesn't exist
if [ ! -f "$USER_DIR/$USERNAME.nix" ]; then
    blue "Creating user configuration file..."
    cat > "$USER_DIR/$USERNAME.nix" <<EOF
{
  inputs,
  den,
  pkgs,
  FTS,
  __findFile,
  ...
}:
{
  # Define the user
  den.users = {
    $USERNAME = {
      # Add to hosts as needed
      # hosts.myhostname = { };
    };
  };

  # $USERNAME user-specific aspect
  den.aspects = {
    $USERNAME = {
      includes = [
        # User configuration
        <FTS.user/admin>
        <FTS.user/autologin>
        (<FTS.user/shell> { default = "fish"; })
        
        # User theme
        (<FTS.theme> { default = "cody"; })
        
        # Applications
        <FTS.apps/browsers>
        <FTS.apps/notes>
        
        # Coding tools
        <FTS.coding>
      ];

      homeManager = { config, lib, pkgs, ... }: {
        # User-specific home-manager configuration
        home.stateVersion = "25.11";
        
        # Example: User-specific packages
        # home.packages = with pkgs; [
        #   # your packages here
        # ];
      };
    };
  };
}
EOF
    green "Created user configuration file"
else
    blue "User configuration file already exists, skipping creation"
fi

echo ""
green "User '$USERNAME' created successfully!"
echo ""
blue "Generated files:"
if [ -f "$AGE_KEY_FILE" ]; then
echo "  - $AGE_KEY_FILE (age private key - keep this safe!)"
fi
echo "  - $USER_DIR/secrets.yaml (encrypted secrets file)"
echo "  - $USER_DIR/$USERNAME.nix (user configuration)"
echo ""
yellow "Next steps:"
echo "  1. Edit secrets: just edit-secrets $USERNAME"
echo "  2. Configure user in $USER_DIR/$USERNAME.nix"
echo "  3. Add user to a host in hosts/<hostname>/<hostname>.nix:"
echo "     den.hosts.x86_64-linux.<hostname>.users.$USERNAME = { };"
echo "  4. Build your configuration: just build <hostname>"

