# Editing SOPS Secrets Files

## Quick Commands

### Edit User Secrets (cody)

```bash
cd /home/cody/.flake
SOPS_AGE_KEY_FILE=sops.key nix develop --command sops --config sops.yaml users/cody/secrets.yaml
```

### Edit Host Secrets (THEBATTLESHIP)

```bash
cd /home/cody/.flake
SOPS_AGE_KEY_FILE=sops.key nix develop --command sops --config sops.yaml hosts/THEBATTLESHIP/secrets.yaml
```

## What Happens

1. SOPS decrypts the file
2. Opens it in your default editor (`$EDITOR` or `vi`)
3. When you save and close, SOPS automatically re-encrypts it

## Viewing Secrets (Read-Only)

If you just want to view without editing:

```bash
# View user secrets
SOPS_AGE_KEY_FILE=sops.key nix develop --command sops --config sops.yaml -d users/cody/secrets.yaml

# View host secrets
SOPS_AGE_KEY_FILE=sops.key nix develop --command sops --config sops.yaml -d hosts/THEBATTLESHIP/secrets.yaml
```

## Setting Your Editor

If you want to use a specific editor:

```bash
# Use vim
EDITOR=vim SOPS_AGE_KEY_FILE=sops.key nix develop --command sops --config sops.yaml users/cody/secrets.yaml

# Use nano
EDITOR=nano SOPS_AGE_KEY_FILE=sops.key nix develop --command sops --config sops.yaml users/cody/secrets.yaml

# Use VS Code
EDITOR="code --wait" SOPS_AGE_KEY_FILE=sops.key nix develop --command sops --config sops.yaml users/cody/secrets.yaml
```

## Example: Adding a Secret

1. **Edit the file:**
   ```bash
   SOPS_AGE_KEY_FILE=sops.key nix develop --command sops --config sops.yaml users/cody/secrets.yaml
   ```

2. **In the editor, add your secret:**
   ```yaml
   cody:
     api_keys:
       openai: "sk-your-actual-key-here"
       github_token: "ghp_your-token-here"
   ```

3. **Save and close** - SOPS automatically encrypts it

## Generating Random Secrets

Before editing, you can generate a random secret:

```bash
# Generate a 64-byte random secret
nix develop --command openssl rand -hex 64

# Copy the output, then paste it into the secrets file when editing
```

## Quick Reference

| Action | Command |
|--------|---------|
| Edit user secrets | `SOPS_AGE_KEY_FILE=sops.key nix develop --command sops --config sops.yaml users/cody/secrets.yaml` |
| Edit host secrets | `SOPS_AGE_KEY_FILE=sops.key nix develop --command sops --config sops.yaml hosts/THEBATTLESHIP/secrets.yaml` |
| View user secrets | `SOPS_AGE_KEY_FILE=sops.key nix develop --command sops --config sops.yaml -d users/cody/secrets.yaml` |
| View host secrets | `SOPS_AGE_KEY_FILE=sops.key nix develop --command sops --config sops.yaml -d hosts/THEBATTLESHIP/secrets.yaml` |
| Generate secret | `nix develop --command openssl rand -hex 64` |

## Using Justfile Commands (Future)

Once the SOPS helper apps are available via `nix run`, you can use:

```bash
# Edit user secrets
just sops-edit users/cody/secrets.yaml

# Edit host secrets  
just sops-edit hosts/THEBATTLESHIP/secrets.yaml
```

But for now, use the `nix develop` commands above.

