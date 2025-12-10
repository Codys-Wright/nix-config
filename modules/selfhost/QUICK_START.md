# SOPS Secrets Management - Quick Start

## What Was Added

I've added a complete set of helper commands to make SOPS secrets management super easy:

### 1. **Flake Apps** (`modules/flake/sops-helpers.nix`)
   - `sops-gen-key` - Generate age key pairs
   - `sops-get-host-key` - Get host's public key from SSH
   - `sops-gen-secret` - Generate random secrets
   - `sops-edit` - Edit encrypted secrets.yaml
   - `sops-view` - View decrypted secrets (read-only)
   - `sops-init-config` - Create sops.yaml configuration
   - `sops-init-secrets` - Create initial secrets.yaml

### 2. **Justfile Commands** (added to `justfile`)
   - `just sops-setup` - One-command setup wizard
   - `just sops-gen-key` - Generate keys
   - `just sops-get-host-key` - Get host key
   - `just sops-gen-secret` - Generate random secret
   - `just sops-edit` - Edit secrets
   - `just sops-view` - View secrets
   - `just sops-init-config` - Create config
   - `just sops-init-secrets` - Create secrets file

### 3. **Dev Shells** (updated `modules/flake/devShells.nix`)
   - Added `age`, `sops`, `ssh-to-age`, and `openssl` to both default and deploy shells

### 4. **Documentation**
   - `SOPS_COMMANDS.md` - Complete command reference
   - `IMPLEMENTATION_STEPS.md` - Step-by-step implementation guide
   - `README.md` - Architecture overview

## Super Quick Start

### For a New Server Setup:

```bash
# 1. One command to set everything up
just sops-setup myserver.com

# 2. Edit your secrets
just sops-edit

# 3. Generate random secrets when needed
SECRET=$(just sops-gen-secret 64)
# Then paste into secrets.yaml when editing
```

### For Local Development:

```bash
# 1. Setup without host key
just sops-setup

# 2. Edit secrets
just sops-edit
```

## Common Workflows

### Adding a New Secret

```bash
# Generate secret
SECRET=$(just sops-gen-secret)

# Edit secrets file
just sops-edit

# Add to YAML in editor:
#   service:
#     new_secret: "paste-secret-here"
```

### Viewing Secrets (without editing)

```bash
just sops-view
```

### Getting Host Key for New Server

```bash
just sops-get-host-key newserver.com
```

## What These Commands Replace

Instead of running these long commands:
```bash
# OLD WAY ❌
nix shell nixpkgs#age --command age-keygen -o keys.txt
nix shell nixpkgs#ssh-to-age --command sh -c 'ssh-keyscan -t ed25519 -4 myserver.com | ssh-to-age'
SOPS_AGE_KEY_FILE=keys.txt nix run --impure nixpkgs#sops -- --config sops.yaml secrets.yaml
nix run nixpkgs#openssl -- rand -hex 64
```

You can now just run:
```bash
# NEW WAY ✅
just sops-gen-key
just sops-get-host-key myserver.com
just sops-edit
just sops-gen-secret
```

## Next Steps

1. **Try the setup**: Run `just sops-setup` to see it in action
2. **Read the docs**: Check `SOPS_COMMANDS.md` for all available commands
3. **Start implementing**: Follow `IMPLEMENTATION_STEPS.md` to create your self-hosting modules

## Files Created/Modified

- ✅ `modules/flake/sops-helpers.nix` - Flake apps for SOPS operations
- ✅ `modules/flake/devShells.nix` - Added SOPS tools to dev shells
- ✅ `justfile` - Added SOPS helper commands
- ✅ `modules/selfhost/SOPS_COMMANDS.md` - Command reference
- ✅ `modules/selfhost/QUICK_START.md` - This file
- ✅ `modules/selfhost/IMPLEMENTATION_STEPS.md` - Implementation guide
- ✅ `modules/selfhost/README.md` - Architecture overview

All commands are ready to use! 🎉

