# SOPS helper commands and apps
# Provides convenient commands for managing SOPS secrets
{
  inputs,
  perSystem,
  ...
}:
{
  perSystem = { pkgs, system, ... }: {
    # Helper apps for SOPS operations
    apps = {
      # Generate a new age key pair
      sops-gen-key = {
        type = "app";
        program = toString (pkgs.writeShellScriptBin "sops-gen-key" ''
          set -e
          KEYS_FILE="''${1:-keys.txt}"
          
          if [ -f "$KEYS_FILE" ]; then
            echo "Error: $KEYS_FILE already exists!"
            echo "If you want to regenerate, delete it first: rm $KEYS_FILE"
            exit 1
          fi
          
          echo "Generating age key pair..."
          ${pkgs.age}/bin/age-keygen -o "$KEYS_FILE"
          
          echo ""
          echo "✓ Key pair generated: $KEYS_FILE"
          echo "⚠️  Keep this file secure and never commit it to git!"
          echo ""
          echo "Public key:"
          ${pkgs.gnugrep}/bin/grep -oP '^public key: \K.*' "$KEYS_FILE" || \
            ${pkgs.gnugrep}/bin/grep "^public key:" "$KEYS_FILE" | ${pkgs.gawk}/bin/awk '{print $3}'
        '');
      };

      # Get target host's public age key from SSH
      sops-get-host-key = {
        type = "app";
        program = toString (pkgs.writeShellScriptBin "sops-get-host-key" ''
          set -e
          
          if [ -z "$1" ]; then
            echo "Usage: sops-get-host-key <hostname> [port]"
            echo "Example: sops-get-host-key myserver.com"
            echo "Example: sops-get-host-key localhost 2222"
            exit 1
          fi
          
          HOST="$1"
          PORT="''${2:-22}"
          
          echo "Fetching SSH host key from $HOST:$PORT..."
          echo ""
          
          ${pkgs.ssh-to-age}/bin/ssh-to-age <<< "$(${pkgs.openssh}/bin/ssh-keyscan -t ed25519 -4 -p "$PORT" "$HOST" 2>/dev/null)" || {
            echo "Error: Failed to get host key. Make sure:"
            echo "  1. The host is accessible"
            echo "  2. SSH is running on the host"
            echo "  3. You can reach port $PORT"
            exit 1
          }
        '');
      };

      # Generate a random secret
      sops-gen-secret = {
        type = "app";
        program = toString (pkgs.writeShellScriptBin "sops-gen-secret" ''
          set -e
          LENGTH="''${1:-64}"
          
          echo "Generating random secret ($LENGTH bytes)..."
          ${pkgs.openssl}/bin/openssl rand -hex "$LENGTH"
        '');
      };

      # Edit secrets.yaml file
      sops-edit = {
        type = "app";
        program = toString (pkgs.writeShellScriptBin "sops-edit" ''
          set -e
          
          KEYS_FILE="''${SOPS_AGE_KEY_FILE:-keys.txt}"
          SECRETS_FILE="''${1:-secrets.yaml}"
          SOPS_CONFIG="''${SOPS_CONFIG_FILE:-sops.yaml}"
          
          if [ ! -f "$KEYS_FILE" ]; then
            echo "Error: Keys file not found: $KEYS_FILE"
            echo "Set SOPS_AGE_KEY_FILE or create keys.txt first"
            echo "Run: nix run .#sops-gen-key"
            exit 1
          fi
          
          if [ ! -f "$SOPS_CONFIG" ]; then
            echo "Error: SOPS config file not found: $SOPS_CONFIG"
            echo "Set SOPS_CONFIG_FILE or create sops.yaml first"
            exit 1
          fi
          
          echo "Editing $SECRETS_FILE..."
          SOPS_AGE_KEY_FILE="$KEYS_FILE" ${pkgs.sops}/bin/sops \
            --config "$SOPS_CONFIG" \
            "$SECRETS_FILE"
        '');
      };

      # View secrets.yaml file (decrypted)
      sops-view = {
        type = "app";
        program = toString (pkgs.writeShellScriptBin "sops-view" ''
          set -e
          
          KEYS_FILE="''${SOPS_AGE_KEY_FILE:-keys.txt}"
          SECRETS_FILE="''${1:-secrets.yaml}"
          SOPS_CONFIG="''${SOPS_CONFIG_FILE:-sops.yaml}"
          
          if [ ! -f "$KEYS_FILE" ]; then
            echo "Error: Keys file not found: $KEYS_FILE"
            exit 1
          fi
          
          if [ ! -f "$SECRETS_FILE" ]; then
            echo "Error: Secrets file not found: $SECRETS_FILE"
            exit 1
          fi
          
          SOPS_AGE_KEY_FILE="$KEYS_FILE" ${pkgs.sops}/bin/sops \
            --config "$SOPS_CONFIG" \
            -d "$SECRETS_FILE"
        '');
      };

      # Create initial sops.yaml template
      sops-init-config = {
        type = "app";
        program = toString (pkgs.writeShellScriptBin "sops-init-config" ''
          set -e
          
          CONFIG_FILE="''${1:-sops.yaml}"
          
          if [ -f "$CONFIG_FILE" ]; then
            echo "Error: $CONFIG_FILE already exists!"
            exit 1
          fi
          
          if [ -z "$2" ]; then
            echo "Usage: sops-init-config [config-file] <your-public-key> [host-public-key]"
            echo ""
            echo "Example:"
            echo "  # Get your public key from keys.txt"
            echo "  MY_KEY=\$(grep '^public key:' keys.txt | awk '{print \$3}')"
            echo "  nix run .#sops-init-config sops.yaml \"\$MY_KEY\""
            echo ""
            echo "Or with host key:"
            echo "  HOST_KEY=\$(nix run .#sops-get-host-key myserver.com)"
            echo "  nix run .#sops-init-config sops.yaml \"\$MY_KEY\" \"\$HOST_KEY\""
            exit 1
          fi
          
          MY_KEY="$2"
          HOST_KEY="''${3:-}"
          
          cat > "$CONFIG_FILE" <<EOF
          keys:
            - &me $MY_KEY
          EOF
          
          if [ -n "$HOST_KEY" ]; then
            cat >> "$CONFIG_FILE" <<EOF
            - &target $HOST_KEY
          EOF
          fi
          
          cat >> "$CONFIG_FILE" <<EOF
          creation_rules:
            - path_regex: secrets.yaml\$
              key_groups:
              - age:
                - *me
          EOF
          
          if [ -n "$HOST_KEY" ]; then
            ${pkgs.gnused}/bin/sed -i 's/- \*me$/- *me\n                - *target/' "$CONFIG_FILE"
          fi
          
          echo "✓ Created $CONFIG_FILE"
          echo ""
          echo "You can now create secrets.yaml:"
          echo "  nix run .#sops-edit"
        '');
      };

      # Create initial secrets.yaml file
      sops-init-secrets = {
        type = "app";
        program = toString (pkgs.writeShellScriptBin "sops-init-secrets" ''
          set -e
          
          SECRETS_FILE="''${1:-secrets.yaml}"
          KEYS_FILE="''${SOPS_AGE_KEY_FILE:-keys.txt}"
          SOPS_CONFIG="''${SOPS_CONFIG_FILE:-sops.yaml}"
          
          if [ -f "$SECRETS_FILE" ]; then
            echo "Error: $SECRETS_FILE already exists!"
            exit 1
          fi
          
          if [ ! -f "$SOPS_CONFIG" ]; then
            echo "Error: SOPS config file not found: $SOPS_CONFIG"
            echo "Create it first: nix run .#sops-init-config"
            exit 1
          fi
          
          if [ ! -f "$KEYS_FILE" ]; then
            echo "Error: Keys file not found: $KEYS_FILE"
            echo "Create it first: nix run .#sops-gen-key"
            exit 1
          fi
          
          # Create a minimal secrets.yaml template
          cat > "$SECRETS_FILE" <<EOF
          # Example secrets structure
          # Edit this file with: nix run .#sops-edit
          
          nextcloud:
            adminpass: "changeme"
          
          lldap:
            user_password: "changeme"
            jwt_secret: "changeme"
          
          authelia:
            jwt_secret: "changeme"
            session_secret: "changeme"
            storage_encryption_key: "changeme"
            hmac_secret: "changeme"
            private_key: "changeme"
          EOF
          
          # Encrypt it
          SOPS_AGE_KEY_FILE="$KEYS_FILE" ${pkgs.sops}/bin/sops \
            --config "$SOPS_CONFIG" \
            -e -i "$SECRETS_FILE"
          
          echo "✓ Created and encrypted $SECRETS_FILE"
          echo ""
          echo "Edit it with: nix run .#sops-edit"
        '');
      };
    };
  };
}

