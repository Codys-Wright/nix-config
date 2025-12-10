# Template Host Setup

This directory contains template files for setting up a new deployment host.

## Required Files

1. **`host_key`** - SSH host key (private key)
   - Generate with: `ssh-keygen -t ed25519 -N "" -f host_key && chmod 600 host_key`
   - See `host_key.example` for instructions

2. **`host_key.pub`** - SSH host key (public key)
   - Generated automatically when you create `host_key`

3. **`ssh`** - SSH private key for deployment
   - Generate with: `ssh-keygen -t ed25519 -N "" -f ssh && chmod 600 ssh`

4. **`ssh.pub`** - SSH public key for deployment
   - Generated automatically when you create `ssh`
   - Used for initrd SSH access

5. **`known_hosts`** - Known hosts file
   - Generate with: `nix run .#gen-knownhosts-file` or manually
   - See `known_hosts.example` for instructions

6. **`facter.json`** - Hardware detection report
   - Generate with: `just generate-hardware <hostname>`
   - Or run `nixos-facter` on the target system

7. **`secrets.yaml`** - Encrypted secrets file
   - Already created with template structure
   - Edit with: `just edit-secrets <hostname>`

## Setup Steps

1. Copy this template directory to `hosts/<your-hostname>/`
2. Generate all required files (see above)
3. Update `template.nix` with your hostname and configuration
4. Set the IP address in the deployment config
5. Deploy!

