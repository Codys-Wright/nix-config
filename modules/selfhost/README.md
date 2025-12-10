# Self-Hosting Services Module Guide

This guide shows how to convert the Nextcloud SSO demo into reusable NixOS modules following the FTS pattern.

## Overview

The Nextcloud SSO setup consists of:
1. **LLDAP** - LDAP identity provider
2. **Authelia** - SSO/OIDC provider
3. **Nextcloud** - File sharing and collaboration platform
4. **SSL Certificates** - Self-signed certificates for HTTPS
5. **SOPS** - Secrets management
6. **Nginx** - Reverse proxy (handled by selfhostblocks)

## Step-by-Step Implementation

### Step 1: Add Flake Inputs

Add these inputs to your `flake.nix`:

```nix
inputs = {
  # ... existing inputs ...
  selfhostblocks.url = "github:ibizaman/selfhostblocks";
  sops-nix.url = "github:Mic92/sops-nix";
};
```

### Step 2: Create SOPS Module

**File**: `modules/selfhost/sops.nix`

This module sets up SOPS for secrets management. It should:
- Import the sops-nix module
- Configure the default SOPS file location
- Set up age key file location

### Step 3: Create SSL Certificate Module

**File**: `modules/selfhost/ssl.nix`

This module handles SSL certificate generation:
- Self-signed CA creation
- Wildcard certificate generation for domains
- Certificate assignment to services

### Step 4: Create LLDAP Module

**File**: `modules/selfhost/lldap.nix`

This module configures LLDAP (Lightweight LDAP):
- Enable LLDAP service
- Configure domain and subdomain
- Set up LDAP port and web UI port
- Configure DC domain
- Link secrets from SOPS

### Step 5: Create Authelia Module

**File**: `modules/selfhost/authelia.nix`

This module configures Authelia SSO provider:
- Enable Authelia service
- Configure domain and subdomain
- Link to LLDAP for authentication
- Configure SSL certificates
- Link all required secrets from SOPS

### Step 6: Create Nextcloud Module

**File**: `modules/selfhost/nextcloud.nix`

This module configures Nextcloud:
- Enable Nextcloud service
- Configure domain and subdomain
- Set data directory
- Configure admin password from SOPS
- Enable apps (preview generator, LDAP, SSO)

### Step 7: Create Nextcloud SSO Meta-Module

**File**: `modules/selfhost/nextcloud-sso.nix`

This module combines all components:
- Includes LLDAP, Authelia, and Nextcloud
- Configures Nextcloud to use LDAP
- Configures Nextcloud to use Authelia for SSO
- Sets up SSL certificates
- Configures DNSmasq for local DNS (optional, for development)

### Step 8: Create Selfhost Meta-Module

**File**: `modules/selfhost/selfhost.nix`

This is the main entry point that includes all self-hosting modules.

## Module Structure Pattern

Each module should follow this pattern:

```nix
{ inputs, lib, den, FTS, ... }:
{
  flake-file.inputs = {
    selfhostblocks.url = "github:ibizaman/selfhostblocks";
    sops-nix.url = "github:Mic92/sops-nix";
  };

  FTS.service-name = {
    description = "Description of the service";
    
    nixos = { config, pkgs, ... }: {
      imports = [
        inputs.selfhostblocks.nixosModules.service-name
        # ... other required modules
      ];
      
      # Service configuration
      shb.service-name = {
        enable = true;
        # ... configuration options
      };
    };
  };
};
```

## Usage Example

Once modules are created, use them in a host configuration:

```nix
{ FTS, ... }:
{
  den.aspects.my-server = {
    includes = [
      FTS.selfhost.nextcloud-sso
    ];
  };
}
```

## Secrets Management

Secrets should be stored in a `secrets.yaml` file encrypted with SOPS. The module should reference secrets like:

```nix
adminPass.result = config.shb.sops.secret."nextcloud/adminpass".result;
shb.sops.secret."nextcloud/adminpass".request = config.shb.nextcloud.adminPass.request;
```

## DNS Configuration

For local development, you can use DNSmasq to resolve domains locally:

```nix
services.dnsmasq = {
  enable = true;
  settings = {
    address = map (hostname: "/${hostname}/127.0.0.1") [
      "example.com"
      "n.example.com"
      "ldap.example.com"
      "auth.example.com"
    ];
  };
};
```

For production, configure your DNS server or use `/etc/hosts`.

## Next Steps

1. Start with the SOPS module (foundation for secrets)
2. Create SSL module (needed for HTTPS)
3. Create LLDAP module (identity provider)
4. Create Authelia module (SSO provider)
5. Create Nextcloud module (main service)
6. Create meta-modules that combine them
7. Test each module incrementally

