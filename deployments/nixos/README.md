# Terraform Deployment for NixOS

This directory contains Terraform configuration to replace `deploy-rs` with a more robust, infrastructure-as-code approach using `nixos-anywhere`.

## Overview

The Terraform configuration uses the `nixos-anywhere` all-in-one module to:
- Install NixOS on remote machines
- Keep configurations up-to-date with `nixos-rebuild`
- Track deployment state and reinstallations
- Provide better error handling and logging
- **Scale to multiple hosts** using JSON configuration files

## Files

- `main.tf` - Main Terraform configuration (uses `for_each` with host files)
- `.gitignore` - Git ignore rules for Terraform files

## Host Configuration

Each host is defined by a `host.tf.json` file in its system directory:

### Example: `systems/x86_64-linux/vm/host.tf.json`
```json
{
  "ipv4": "192.168.122.217",
  "hostname": "vm"
}
```

### Adding New Hosts

1. **Create a new system directory** (if needed):
   ```bash
   mkdir -p systems/x86_64-linux/my-server
   ```

2. **Create the host configuration**:
   ```bash
   cp systems/host.tf.json.template systems/x86_64-linux/my-server/host.tf.json
   ```

3. **Edit the host file**:
   ```json
   {
     "ipv4": "192.168.1.100",
     "hostname": "my-server"
   }
   ```

4. **Create the NixOS configuration**:
   ```bash
   # Create systems/x86_64-linux/my-server/default.nix
   ```

The Terraform configuration will automatically:
- Find all `host.tf.json` files in `systems/**/`
- Deploy to each host in parallel
- Use the hostname to build the correct NixOS configuration
- Generate hardware configs in the appropriate directories

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

Everything is configured through `host.tf.json` files - no additional configuration needed!

### Phases

The deployment runs these phases by default:
1. `kexec` - Boot into NixOS installer
2. `disko` - Partition and format disk
3. `install` - Install NixOS
4. `reboot` - Reboot into new system

### Instance Tracking

Terraform tracks instance IDs to know when to reinstall. The instance ID changes when:
- You manually change the IP address in `host.tf.json`
- The IP address changes (default behavior)

## Advantages over deploy-rs

1. **State Management** - Terraform tracks deployment state
2. **Reinstallation Support** - Can reinstall when instance ID changes
3. **Better Error Handling** - More robust error reporting
4. **Infrastructure as Code** - Declarative configuration
5. **Integration** - Works seamlessly with `nixos-anywhere`
6. **Scalability** - Easy to add new hosts with JSON files
7. **Parallel Deployment** - Deploy to multiple hosts simultaneously

## Troubleshooting

### SSH Key Authentication
For better security, use SSH keys instead of passwords:
1. Add your public key to the target machine
2. Ensure SSH keys are properly configured

### Debug Logging
The configuration uses minimal settings for maximum compatibility.

## Migration from deploy-rs

1. **Backup your current configuration**
2. **Create host.tf.json files** for each system
3. **Initialize Terraform:** `just terraform-init`
4. **Plan deployment:** `just terraform-plan`
5. **Apply deployment:** `just terraform-apply`
6. **Update your workflow:** Use `just deploy` instead of `just deploy-legacy`

## Security Notes

- Host configuration files (`host.tf.json`) should be committed to version control
- Consider using SSH keys instead of passwords
- Review the `.gitignore` file to ensure sensitive files are not committed

## Structure

```
deployments/
└── nixos/
    ├── main.tf              # Terraform configuration
    ├── .gitignore           # Git ignore rules
    └── README.md           # This file
``` 