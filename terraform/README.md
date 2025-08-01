# Terraform Deployment for NixOS

This directory contains Terraform configuration to replace `deploy-rs` with a more robust, infrastructure-as-code approach using `nixos-anywhere`.

## Overview

The Terraform configuration uses the `nixos-anywhere` all-in-one module to:
- Install NixOS on remote machines
- Keep configurations up-to-date with `nixos-rebuild`
- Track deployment state and reinstallations
- Provide better error handling and logging

## Files

- `main.tf` - Main Terraform configuration
- `variables.tf` - Variable definitions
- `terraform.tfvars` - Variable values (customize for your environment)
- `.gitignore` - Git ignore rules for Terraform files

## Usage

### Initial Setup

1. **Initialize Terraform:**
   ```bash
   just terraform-init
   ```

2. **Plan the deployment:**
   ```bash
   just terraform-plan
   ```

3. **Apply the deployment:**
   ```bash
   just terraform-apply
   ```

### Quick Deployment

Use the simplified commands:
```bash
just deploy          # Deploy using Terraform
just deploy-node vm  # Deploy specific node
```

### Configuration

Edit `terraform.tfvars` to customize:
- Target host IP
- SSH credentials
- Deployment phases
- Debug logging

### Phases

The deployment runs these phases by default:
1. `kexec` - Boot into NixOS installer
2. `disko` - Partition and format disk
3. `install` - Install NixOS
4. `reboot` - Reboot into new system

### Instance Tracking

Terraform tracks instance IDs to know when to reinstall. The instance ID changes when:
- You manually change it in `terraform.tfvars`
- The timestamp-based ID changes (default behavior)

## Advantages over deploy-rs

1. **State Management** - Terraform tracks deployment state
2. **Reinstallation Support** - Can reinstall when instance ID changes
3. **Better Error Handling** - More robust error reporting
4. **Infrastructure as Code** - Declarative configuration
5. **Integration** - Works seamlessly with `nixos-anywhere`

## Troubleshooting

### Debug Logging
Enable debug logging in `terraform.tfvars`:
```hcl
debug_logging = true
```

### Remote Building
Build on the remote machine instead of locally:
```hcl
build_on_remote = true
```

### Custom Phases
Modify deployment phases:
```hcl
phases = ["kexec", "disko", "install", "reboot"]
```

### SSH Key Authentication
For better security, use SSH keys instead of passwords:
1. Add your public key to the target machine
2. Remove `target_password` from `terraform.tfvars`

## Migration from deploy-rs

1. **Backup your current configuration**
2. **Initialize Terraform:** `just terraform-init`
3. **Plan deployment:** `just terraform-plan`
4. **Apply deployment:** `just terraform-apply`
5. **Update your workflow:** Use `just deploy` instead of `just deploy-legacy`

## Security Notes

- The `terraform.tfvars` file contains sensitive information and is gitignored
- Consider using SSH keys instead of passwords
- Review the `.gitignore` file to ensure sensitive files are not committed 