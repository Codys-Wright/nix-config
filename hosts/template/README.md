# Host Template

This directory contains templates for creating new hosts.

## Files

- **secrets-example.yaml**: Template for host-level secrets (system services, infrastructure, deployment keys)

## Usage

The `secrets-example.yaml` file is automatically used by the `just new-host <hostname>` command.

You can also manually create a new host by:

1. Copy the template: `cp hosts/template/secrets-example.yaml hosts/<hostname>/secrets.yaml`
2. Replace `<hostname>` with your actual hostname
3. Fill in your secrets
4. Encrypt with: `SOPS_AGE_KEY_FILE=sops.key nix develop --command sops --config sops.yaml -e -i hosts/<hostname>/secrets.yaml`

## What Goes Here

Host-level secrets are for **system-wide configuration**:
- Deployment SSH keys
- System passwords
- Service credentials (databases, web servers)
- Infrastructure API keys (cloud providers, DNS)
- SSL/TLS certificates
- System monitoring and alerting credentials

For **personal user secrets** (git configs, personal API keys), see `users/template/`.
