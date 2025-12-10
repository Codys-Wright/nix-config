# SOPS Commands Quick Reference

This guide provides easy-to-use commands for managing SOPS secrets.

## Quick Start

### 1. Initial Setup (One-time)

```bash
# Option A: Full setup with host key (recommended for remote servers)
just sops-setup myserver.com

# Option B: Local setup only (for testing/development)
just sops-setup
```

This will:
- Generate your age key pair (`keys.txt`)
- Create `sops.yaml` configuration
- Create initial `secrets.yaml` file

### 2. Edit Secrets

```bash
# Edit secrets.yaml (opens in your default editor)
just sops-edit

# Or specify a different file
just sops-edit my-secrets.yaml
```

### 3. View Secrets (Read-only)

```bash
# View decrypted secrets without editing
just sops-view
```

### 4. Generate Random Secrets

```bash
# Generate 64-byte hex secret (default)
just sops-gen-secret

# Generate 128-byte hex secret
just sops-gen-secret 128
```

## Individual Commands

### Key Management

```bash
# Generate new age key pair
just sops-gen-key [keys.txt]

# Get host's public key from SSH
just sops-get-host-key <hostname> [port]
# Example: just sops-get-host-key myserver.com
# Example: just sops-get-host-key localhost 2222
```

### Configuration

```bash
# Create sops.yaml config file
just sops-init-config [sops.yaml] <your-public-key> [host-public-key]

# Create initial secrets.yaml
just sops-init-secrets [secrets.yaml]
```

### Secrets Management

```bash
# Edit secrets (encrypted file)
just sops-edit [secrets.yaml]

# View secrets (decrypted, read-only)
just sops-view [secrets.yaml]

# Generate random secret
just sops-gen-secret [length]
```

## Using Nix Run Directly

If you prefer using `nix run` directly:

```bash
# Generate key
nix run .#sops-gen-key

# Get host key
nix run .#sops-get-host-key -- myserver.com

# Generate secret
nix run .#sops-gen-secret -- 64

# Edit secrets
nix run .#sops-edit

# View secrets
nix run .#sops-view
```

## Environment Variables

You can set these environment variables to customize behavior:

```bash
# Set custom keys file location
export SOPS_AGE_KEY_FILE=/path/to/keys.txt

# Set custom SOPS config file
export SOPS_CONFIG_FILE=/path/to/sops.yaml

# Then use commands normally
just sops-edit
```

## Workflow Examples

### Example 1: Setting up secrets for a new server

```bash
# 1. Generate your key pair
just sops-gen-key

# 2. Get server's public key
SERVER_KEY=$(just sops-get-host-key myserver.com)

# 3. Get your public key
MY_KEY=$(grep '^public key:' keys.txt | awk '{print $3}')

# 4. Create sops.yaml with both keys
just sops-init-config sops.yaml "$MY_KEY" "$SERVER_KEY"

# 5. Create initial secrets.yaml
just sops-init-secrets

# 6. Edit and add your secrets
just sops-edit
```

### Example 2: Adding a new secret

```bash
# 1. Generate a random secret
SECRET=$(just sops-gen-secret 64)
echo "Generated secret: $SECRET"

# 2. Edit secrets.yaml
just sops-edit

# 3. Add the secret to the YAML file in your editor
# Example:
#   nextcloud:
#     adminpass: "paste-secret-here"
```

### Example 3: Adding a new host key

```bash
# 1. Get the new host's public key
NEW_HOST_KEY=$(just sops-get-host-key newserver.com)

# 2. Edit sops.yaml manually or use sops-edit to add the key
# Add to the age recipients list in sops.yaml
```

## Troubleshooting

### "Keys file not found"
```bash
# Generate keys first
just sops-gen-key
```

### "SOPS config file not found"
```bash
# Create config first
MY_KEY=$(grep '^public key:' keys.txt | awk '{print $3}')
just sops-init-config sops.yaml "$MY_KEY"
```

### "Secrets file not found"
```bash
# Create initial secrets file
just sops-init-secrets
```

### "Permission denied" when editing
```bash
# Make sure keys.txt has correct permissions
chmod 600 keys.txt
```

## Security Notes

⚠️ **Important Security Practices:**

1. **Never commit `keys.txt` to git** - Add it to `.gitignore`
2. **Keep `keys.txt` secure** - Store it in a password manager or secure location
3. **Use different keys for different environments** - Dev, staging, production
4. **Rotate keys periodically** - Generate new keys and update secrets
5. **Limit access to secrets.yaml** - Even though encrypted, limit who can decrypt

## Integration with NixOS

Once you have `secrets.yaml` set up, reference it in your NixOS configuration:

```nix
{
  imports = [
    inputs.sops-nix.nixosModules.default
    inputs.selfhostblocks.nixosModules.sops
  ];

  sops.defaultSopsFile = ./secrets.yaml;

  # Reference secrets
  shb.sops.secret."nextcloud/adminpass".request = 
    config.shb.nextcloud.adminPass.request;
  shb.nextcloud.adminPass.result = 
    config.shb.sops.secret."nextcloud/adminpass".result;
}
```

