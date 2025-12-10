# Adding a New Host

This guide walks you through adding a new NixOS host to your flake configuration.

## Overview

Adding a new host involves:
1. Creating the host directory structure
2. Generating SSH keys (if needed)
3. Creating the host configuration file
4. Optionally generating hardware configuration
5. Setting up deployment (if deploying remotely)
6. Testing the configuration

## Step-by-Step Guide

### Step 1: Create Host Directory

Create a directory for your new host:

```bash
mkdir -p hosts/myserver
cd hosts/myserver
```

### Step 2: Generate SSH Keys (for Remote Deployment)

If you'll be deploying to this host remotely, generate SSH keys:

```bash
# Generate SSH key for connecting to the host
ssh-keygen -t ed25519 -N "" -f ssh -C "myserver-deploy"
chmod 600 ssh

# Generate host key (for known_hosts)
ssh-keygen -t ed25519 -N "" -f host_key -C "myserver-host"
chmod 600 host_key
```

This creates:
- `ssh` / `ssh.pub` - Key for SSH connections to the host
- `host_key` / `host_key.pub` - Host key for known_hosts verification

### Step 3: Generate Hardware Configuration (Optional but Recommended)

If you want automatic hardware detection, generate a facter report:

#### Option A: Generate on the Target System

If you have access to the target system:

```bash
# On the target system, run:
nix run github:numtide/nixos-facter#nixos-facter > facter.json

# Copy facter.json to your flake:
# scp facter.json user@your-machine:/path/to/.flake/hosts/myserver/
```

#### Option B: Generate via SSH

If the host is already accessible via SSH:

```bash
# From your flake directory:
just generate-hardware myserver hosts/myserver/facter.json
```

#### Option C: Generate Locally

If you're running this on the target system:

```bash
just generate-hardware
# This creates facter.json in the current directory
```

### Step 4: Create Host Configuration File

Create `hosts/myserver/myserver.nix`:

```nix
{ inputs, den, pkgs, FTS, ... }:
{
  # Define the host
  den.hosts.x86_64-linux = {
    myserver = {
      description = "My server description";
      users.cody = { };  # Add users who should have access
      aspect = "myserver";  # Reference to the aspect below
    };
  };

  # Define the host's aspect (configuration)
  den.aspects = {
    myserver = {
      # Include aspects that apply to this host
      includes = [
        FTS.facter              # Hardware detection (if using facter)
        FTS.deployment-config   # Deployment options (if deploying remotely)
        # Add other aspects as needed:
        # FTS.hardware
        # FTS.kernel
        # etc.
      ];

      # NixOS configuration for this host
      nixos = { config, lib, pkgs, ... }: {
        # Basic system configuration
        networking.hostName = "myserver";
        
        # Optional: Use facter report for hardware detection
        facter.reportPath = ./facter.json;

        # Optional: Deployment configuration (for remote deployment)
        deployment = {
          enable = true;
          ip = "192.168.1.100";  # Or hostname like "myserver.example.com"
          sshPort = 22;
          sshUser = "root";
          sshPrivateKeyPath = "./hosts/myserver/ssh";
          sshAuthorizedKey = "./hosts/myserver/ssh.pub";
          hostKeyPath = "./hosts/myserver/host_key";
          hostKeyPub = "./hosts/myserver/host_key.pub";
          knownHostsPath = "./hosts/myserver/known_hosts";
        };

        # Your host-specific configuration goes here
        # For example:
        # - Services
        # - Packages
        # - Network settings
        # - User accounts
        # - etc.
      };
    };
  };
}
```

### Step 5: Generate Known Hosts File (for Remote Deployment)

If deploying remotely, generate the known_hosts file:

```bash
cd /home/cody/.flake

# Generate known_hosts from host key
# This assumes you have the host accessible
ssh-keyscan -t ed25519 -p 22 myserver.example.com >> hosts/myserver/known_hosts

# Or if you have the host_key.pub, you can use:
# (This requires a helper script - see deployment module docs)
```

### Step 6: Create Secrets File (if using SOPS)

If you're using SOPS for secrets management:

```bash
cd /home/cody/.flake

# Create encrypted secrets file for this host
just edit-secrets myserver
# This will create hosts/myserver/secrets.yaml if it doesn't exist

# Add any host-specific secrets:
# - User passwords
# - Service credentials
# - API keys
# etc.
```

### Step 7: Regenerate Flake

After creating the host configuration, regenerate your flake:

```bash
nix run .#write-flake
```

This ensures all new inputs and configurations are properly integrated.

### Step 8: Test the Configuration

Build the configuration to check for errors:

```bash
# Build the configuration (doesn't switch)
just build myserver

# Or check if it evaluates correctly
nix flake check
```

### Step 9: Deploy (if Remote)

If this is a remote host and you've configured deployment:

```bash
# Deploy to this specific host
nix run .#deploy-rs -- --hosts myserver

# Or deploy all hosts
nix run .#deploy-rs
```

### Step 10: Switch (if Local)

If this is the local machine:

```bash
# Switch to this configuration
just switch myserver
```

## Complete Example

Here's a complete example for a server host:

```nix
# hosts/webserver/webserver.nix
{ inputs, den, pkgs, FTS, ... }:
{
  den.hosts.x86_64-linux = {
    webserver = {
      description = "Web server hosting my sites";
      users.cody = { };
      aspect = "webserver";
    };
  };

  den.aspects = {
    webserver = {
      includes = [
        FTS.facter
        FTS.deployment-config
        FTS.hardware
        FTS.kernel
      ];

      nixos = { config, lib, pkgs, ... }: {
        networking.hostName = "webserver";
        
        # Use facter for hardware detection
        facter.reportPath = ./facter.json;

        # Deployment configuration
        deployment = {
          enable = true;
          ip = "192.168.1.10";
          sshPort = 22;
          sshUser = "root";
          sshPrivateKeyPath = "./hosts/webserver/ssh";
          sshAuthorizedKey = "./hosts/webserver/ssh.pub";
          hostKeyPath = "./hosts/webserver/host_key";
          hostKeyPub = "./hosts/webserver/host_key.pub";
          knownHostsPath = "./hosts/webserver/known_hosts";
        };

        # Enable SSH
        services.openssh = {
          enable = true;
          settings.PasswordAuthentication = false;
          openFirewall = true;
        };

        # Install packages
        environment.systemPackages = with pkgs; [
          nginx
          certbot
        ];

        # Configure services
        services.nginx = {
          enable = true;
          # ... nginx config
        };
      };
    };
  };
}
```

## Quick Reference

### Directory Structure

```
hosts/
  myserver/
    myserver.nix          # Host configuration
    facter.json            # Hardware report (optional)
    ssh                    # SSH private key (for deployment)
    ssh.pub                # SSH public key
    host_key               # Host SSH key
    host_key.pub           # Host SSH public key
    known_hosts            # SSH known hosts
    secrets.yaml           # Encrypted secrets (if using SOPS)
```

### Common Commands

```bash
# Generate hardware config
just generate-hardware myserver hosts/myserver/facter.json

# Create/edit secrets
just edit-secrets myserver

# Build configuration
just build myserver

# Switch configuration (local)
just switch myserver

# Deploy configuration (remote)
nix run .#deploy-rs -- --hosts myserver

# Regenerate flake
nix run .#write-flake
```

## Troubleshooting

### Configuration Won't Build

- Check for syntax errors in your `.nix` file
- Ensure all referenced aspects exist
- Verify file paths are correct (use `./` for relative paths)

### Deployment Fails

- Verify SSH keys are correct
- Check that `known_hosts` file is generated
- Ensure the host is accessible via SSH
- Verify `deployment.enable = true` is set

### Hardware Detection Not Working

- Make sure `FTS.facter` is in your includes
- Verify `facter.json` exists and is valid JSON
- Check that `facter.reportPath` points to the correct file

### Flake Inputs Missing

- Run `nix run .#write-flake` to regenerate flake
- Check that `modules/flake/deployment-inputs.nix` is included
- Verify inputs are properly defined

## Next Steps

After adding your host:

1. **Test locally** (if possible) using `just vm myserver`
2. **Set up services** by adding aspects or direct configuration
3. **Configure secrets** using SOPS
4. **Deploy** to the remote host
5. **Monitor** and iterate on your configuration

## See Also

- [Deployment Module README](../modules/deployment/README.md) - Detailed deployment documentation
- [Managing Secrets](./managing-secrets.md) - SOPS secrets management
- [Deployment Tools](../modules/deployment/DEPLOYMENT_TOOLS.md) - Available deployment tools

