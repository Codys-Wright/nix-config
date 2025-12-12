# User Template

This directory contains templates for creating new user configurations.

## Files

- **secrets-example.yaml**: Template for user-level secrets (personal git configs, API keys, passwords)

## Usage

To create secrets for a new user:

1. Copy the template: `cp users/template/secrets-example.yaml users/<username>/secrets.yaml`
2. Replace `<username>` with the actual username
3. Fill in your personal secrets
4. Encrypt with: `SOPS_AGE_KEY_FILE=sops.key nix develop --command sops --config sops.yaml -e -i users/<username>/secrets.yaml`

## What Goes Here

User-level secrets are for **personal configuration**:
- Git credentials (email, username, tokens)
- Personal SSH keys (GitHub, GitLab, personal servers)
- Development API keys (OpenAI, Anthropic, cloud services)
- Personal service credentials (password managers, VPNs)
- Package registry tokens (npm, PyPI, Docker Hub)
- Messaging tokens (Slack, Discord, Telegram)
- User account passwords

For **system-wide secrets** (services, infrastructure), see `hosts/template/`.

