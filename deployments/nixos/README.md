# NixOS Terraform Deployment

This directory contains the Terraform configuration for deploying NixOS systems using `nixos-anywhere`.

## Directory Structure

Each host should be organized in its own directory under `hosts/<hostname>/`:

```
hosts/
├── THEBATTLESHIP/
│   ├── default.nix              # Host NixOS configuration (den framework)
│   ├── host.tf.json             # Terraform deployment configuration
│   └── hardware-configuration.nix  # Hardware-specific configuration (optional)
├── starcommand/
│   ├── default.nix
│   └── host.tf.json
└── voyager/
    ├── default.nix
    └── host.tf.json
```

## Host Configuration File

Each host directory should contain a `host.tf.json` file with the following structure:

```json
{
  "ipv4": "192.168.1.XXX",
  "hostname": "THEBATTLESHIP",
  "install_user": "nixos",
  "install_port": 22,
  "ssh_user": "root",
  "ssh_port": 22,
  "install_password": "optional-password"
}
```

### Required Fields:
- `ipv4`: IPv4 address of the target system
- `hostname`: Hostname (must match the directory name and nixosConfigurations key)

### Optional Fields:
- `install_user`: SSH user for initial installation (default: "nixos")
- `install_port`: SSH port for installation (default: 22)
- `ssh_user`: SSH user after installation (default: "root")
- `ssh_port`: SSH port after installation (default: 22)
- `install_password`: Password for installation (if not using SSH keys)

## Prerequisites

### Required Terraform Providers

The deployment requires the following Terraform providers:

- `hashicorp/null` (~> 3.0)
- `hashicorp/external` (~> 2.0)

These are automatically provided by the `shell.nix` in this directory.

### Entering the Terraform Shell

```bash
cd deployments/nixos
NIXPKGS_ALLOW_UNFREE=1 nix-shell
# or use just
just terraform-shell
```

## Deployment

### Deploy to All Hosts

```bash
just terraform-init
just terraform-plan
just terraform-apply
```

### Deploy to a Specific Host

```bash
just terraform-apply-host THEBATTLESHIP
```

Or using terraform directly:

```bash
cd deployments/nixos
terraform apply -var="target_host=THEBATTLESHIP" -auto-approve
```

## Features

- **Automatic Host Discovery**: Automatically discovers all hosts from `hosts/*/host.tf.json` files
- **Selective Deployment**: Can target specific hosts using the `target_host` variable
- **Remote Building**: Builds NixOS configurations on the remote machine for better performance
- **Instance Tracking**: Uses the host's IP as instance ID to track when reinstalls are needed

## NixOS Configuration

The deployment expects your NixOS configurations to be available as flake outputs:

- System configuration: `.#nixosConfigurations.<hostname>.config.system.build.toplevel`
- Disko script: `.#nixosConfigurations.<hostname>.config.system.build.diskoScript`

The `hostname` in `host.tf.json` must match the key in your `nixosConfigurations` (which is managed by the `den` framework).

## Adding a New System

1. Create a directory: `hosts/<hostname>/`
2. Add your host configuration: `default.nix` (using den framework)
3. Add hardware configuration: `hardware-configuration.nix` (if needed)
4. Create `host.tf.json` with deployment settings:

```json
{
  "ipv4": "192.168.1.XXX",
  "hostname": "your-hostname"
}
```

5. The system will be automatically discovered by Terraform!

## Security Notes

- The deployment uses SSH keys for authentication when possible
- Passwords can be stored in `host.tf.json` files (consider using encrypted secrets for production)
- Consider using SSH agent or encrypted secrets for production deployments

## Troubleshooting

### Enable Debug Logging

Debug logging is enabled by default in `main.tf`. To disable, set `debug_logging = false`.

### Manual Deployment

If Terraform deployment fails, you can manually deploy using:

```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake .#THEBATTLESHIP \
  --target-host root@192.168.1.XXX \
  --env-password \
  --build-on remote
```
