# NixOS Terraform Deployment

This directory contains the Terraform configuration for deploying NixOS systems using `nixos-anywhere`.

## Prerequisites

### Required Terraform Providers

The deployment requires the following Terraform providers:

- `hashicorp/null` (~> 3.0)
- `hashicorp/external` (~> 2.0)

You can install these providers using Nix:

```bash
nix-shell -p '(pkgs.terraform.withPlugins (p: [ p.null p.external ]))'
```

Or add this to your `flake.nix` devshell:

```nix
packages = [ (pkgs.terraform.withPlugins (p: [ p.null p.external ])) ];
```

## Configuration

### Host Configuration

Each host is configured via a `host.tf.json` file in the `systems/x86_64-linux/<hostname>/` directory. The file should contain:

```json
{
  "ipv4": "192.168.1.83",
  "hostname": "THEBATTLESHIP",
  "install_password": "your-password"
}
```

### Deployment

To deploy to all hosts:

```bash
cd deployments/nixos
terraform init
terraform plan
terraform apply
```

To deploy to a specific host:

```bash
terraform apply -var="target_host=THEBATTLESHIP"
```

## Features

- **Automatic Host Discovery**: Automatically discovers all hosts from the `systems/` directory
- **Selective Deployment**: Can target specific hosts using the `target_host` variable
- **Remote Building**: Builds NixOS configurations on the remote machine for better performance
- **Instance Tracking**: Uses the host's IP as instance ID to track when reinstalls are needed

## NixOS Configuration

The deployment expects your NixOS configurations to be available as flake outputs:

- System configuration: `.#nixosConfigurations.<hostname>.config.system.build.toplevel`
- Disko script: `.#nixosConfigurations.<hostname>.config.system.build.diskoScript`

## Security Notes

- The deployment uses SSH keys for authentication
- Passwords are stored in the host configuration files
- Consider using SSH agent or encrypted secrets for production deployments

## Troubleshooting

### Enable Debug Logging

Uncomment the `debug_logging = true` line in `main.tf` to enable verbose output.

### Manual Deployment

If Terraform deployment fails, you can manually deploy using:

```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake .#THEBATTLESHIP \
  --target-host root@192.168.1.83 \
  --env-password \
  --build-on remote
``` 