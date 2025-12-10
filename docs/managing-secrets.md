# Managing Secrets with SOPS

This guide explains how to securely manage secrets in your NixOS configuration using SOPS (Secrets Operations).

## What is SOPS?

SOPS (Secrets OPerationS) is a tool that encrypts your secrets file before storing it in git. The secrets are encrypted with multiple keys:
- **Your private key** - Allows you to edit the secrets
- **Target host's private key** - Allows the server to decrypt secrets when deploying

This means:
- ✅ Secrets are encrypted in git (safe to commit)
- ✅ Only you and the target server can decrypt
- ✅ Secrets are automatically decrypted on the server during deployment

## Prerequisites

The helper commands are already set up in this flake. You just need to:

1. Make sure you're in the flake directory
2. Have access to the target server (for getting its SSH key)

## Quick Start

### Step 1: Initial Setup

For a **remote server**:
```bash
just sops-setup myserver.com
```

For **local development/testing**:
```bash
just sops-setup
```

This single command will:
1. Generate your age key pair (`keys.txt`)
2. Get the server's public key (if provided)
3. Create `sops.yaml` configuration
4. Create initial `secrets.yaml` file

### Step 2: Edit Your Secrets

```bash
just sops-edit
```

This opens `secrets.yaml` in your editor. The file is automatically encrypted when you save.

### Step 3: Use Secrets in NixOS

Reference secrets in your NixOS configuration:

```nix
{
  imports = [
    inputs.sops-nix.nixosModules.default
    inputs.selfhostblocks.nixosModules.sops
  ];

  sops.defaultSopsFile = ./secrets.yaml;

  # Reference a secret
  shb.sops.secret."nextcloud/adminpass".request = 
    config.shb.nextcloud.adminPass.request;
  shb.nextcloud.adminPass.result = 
    config.shb.sops.secret."nextcloud/adminpass".result;
}
```

## Common Workflows

### Adding a New Secret

1. **Generate a random secret** (optional):
   ```bash
   SECRET=$(just sops-gen-secret 64)
   echo $SECRET  # Copy this value
   ```

2. **Edit secrets.yaml**:
   ```bash
   just sops-edit
   ```

3. **Add to YAML structure**:
   ```yaml
   nextcloud:
     adminpass: "your-secret-here"
     new_secret: "another-secret"
   ```

4. **Save and close** - SOPS automatically encrypts the file

### Viewing Secrets (Read-only)

To view secrets without editing:
```bash
just sops-view
```

### Adding a New Server

If you need to add another server that can decrypt secrets:

1. **Get the server's public key**:
   ```bash
   SERVER_KEY=$(just sops-get-host-key newserver.com)
   echo $SERVER_KEY
   ```

2. **Edit sops.yaml** to add the new key:
   ```bash
   # Edit sops.yaml manually or use your editor
   # Add the new key to the age recipients list
   ```

3. **Re-encrypt secrets.yaml**:
   ```bash
   just sops-edit  # Just open and save to re-encrypt
   ```

### Generating Random Secrets

Generate secure random secrets of any length:

```bash
# 64 bytes (default)
just sops-gen-secret

# 128 bytes
just sops-gen-secret 128

# 32 bytes
just sops-gen-secret 32
```

## File Structure

After setup, you'll have these files:

```
.flake/
├── keys.txt          # Your private age key (NEVER commit to git!)
├── sops.yaml         # SOPS configuration (safe to commit)
└── secrets.yaml      # Encrypted secrets (safe to commit)
```

### What Goes in Each File

**`keys.txt`** (Private - Never commit!)
- Your private age key
- Used to encrypt/decrypt secrets
- Keep this secure!

**`sops.yaml`** (Safe to commit)
- Configuration for SOPS
- Lists which keys can decrypt secrets
- Example:
  ```yaml
  keys:
    - &me age1abc123...
    - &server age1def456...
  creation_rules:
    - path_regex: secrets.yaml$
      key_groups:
      - age:
        - *me
        - *server
  ```

**`secrets.yaml`** (Safe to commit - it's encrypted!)
- Your actual secrets, but encrypted
- Looks like gibberish when encrypted
- Only decrypts on the target server

## Best Practices

### 🔒 Security

1. **Never commit `keys.txt`**
   - Add to `.gitignore`:
     ```gitignore
     keys.txt
     *.key
     ```

2. **Use different keys for different environments**
   - Dev, staging, production should have separate keys

3. **Rotate keys periodically**
   - Generate new keys and update secrets

4. **Limit access to keys.txt**
   - Store in password manager or secure location
   - Use `chmod 600 keys.txt`

### 📝 Organization

1. **Group secrets by service**:
   ```yaml
   nextcloud:
     adminpass: "..."
     db_password: "..."
   
   lldap:
     user_password: "..."
     jwt_secret: "..."
   ```

2. **Use descriptive names**:
   - `nextcloud/adminpass` not `secret1`
   - `lldap/jwt_secret` not `jwt`

3. **Document secrets**:
   - Add comments in your NixOS config explaining what each secret is for

### 🔄 Workflow

1. **Generate secrets randomly** when possible:
   ```bash
   SECRET=$(just sops-gen-secret)
   ```

2. **Test locally first** before deploying to production

3. **Backup keys.txt** securely (password manager, encrypted storage)

## Troubleshooting

### "Keys file not found"

```bash
# Generate keys first
just sops-gen-key
```

### "SOPS config file not found"

```bash
# Create config
MY_KEY=$(grep '^public key:' keys.txt | awk '{print $3}')
just sops-init-config sops.yaml "$MY_KEY"
```

### "Secrets file not found"

```bash
# Create initial secrets file
just sops-init-secrets
```

### "Permission denied"

```bash
# Fix key file permissions
chmod 600 keys.txt
```

### Secrets not decrypting on server

1. **Check server has the key**:
   - Verify the server's public key is in `sops.yaml`
   - Make sure you got the correct key from the server

2. **Check SOPS configuration**:
   - Verify `sops.defaultSopsFile` points to the right file
   - Ensure `sops.age.keyFile` is set correctly on the server

3. **Check file paths**:
   - Make sure `secrets.yaml` is in the expected location
   - Verify the path in your NixOS config matches

### "Cannot decrypt secrets.yaml"

- Make sure `keys.txt` is the correct key file
- Verify the key was used to encrypt the secrets
- Check that `sops.yaml` configuration is correct

## Available Commands

### Setup Commands

- `just sops-setup [hostname]` - Complete setup wizard
- `just sops-gen-key` - Generate age key pair
- `just sops-init-config` - Create sops.yaml
- `just sops-init-secrets` - Create initial secrets.yaml

### Management Commands

- `just sops-edit` - Edit encrypted secrets
- `just sops-view` - View decrypted secrets (read-only)
- `just sops-gen-secret [length]` - Generate random secret

### Utility Commands

- `just sops-get-host-key <hostname> [port]` - Get host's public key

## Integration with Self-Hosting Services

When setting up services like Nextcloud, LLDAP, or Authelia:

1. **Create secrets in secrets.yaml**:
   ```yaml
   nextcloud:
     adminpass: "generated-secret"
   
   lldap:
     user_password: "generated-secret"
     jwt_secret: "generated-secret"
   ```

2. **Reference in NixOS modules**:
   ```nix
   shb.nextcloud.adminPass.result = 
     config.shb.sops.secret."nextcloud/adminpass".result;
   shb.sops.secret."nextcloud/adminpass".request = 
     config.shb.nextcloud.adminPass.request;
   ```

3. **Deploy** - Secrets are automatically decrypted on the server

## Advanced Usage

### Using Environment Variables

Customize file locations:

```bash
export SOPS_AGE_KEY_FILE=/custom/path/keys.txt
export SOPS_CONFIG_FILE=/custom/path/sops.yaml
just sops-edit /custom/path/secrets.yaml
```

### Multiple Secrets Files

You can have multiple secrets files for different purposes:

```bash
# Edit production secrets
just sops-edit secrets-prod.yaml

# Edit development secrets
just sops-edit secrets-dev.yaml
```

Just make sure each has its own entry in `sops.yaml` or use separate config files.

## Next Steps

1. **Set up your first service**: Follow the self-hosting implementation guide
2. **Read the command reference**: See `modules/selfhost/SOPS_COMMANDS.md` for all commands
3. **Explore examples**: Check the Nextcloud demo for real-world usage

## Getting Help

- **Command reference**: `modules/selfhost/SOPS_COMMANDS.md`
- **Implementation guide**: `modules/selfhost/IMPLEMENTATION_STEPS.md`
- **Architecture overview**: `modules/selfhost/README.md`

## Security Reminder

⚠️ **Remember**: 
- `keys.txt` is your master key - protect it!
- Never commit `keys.txt` to git
- Use strong, randomly generated secrets
- Rotate keys and secrets periodically
- Limit who has access to `keys.txt`

