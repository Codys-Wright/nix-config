# Implementation Steps Checklist

## Prerequisites
- [ ] Understand the demo structure in `/home/cody/Documents/nix-reference/selfhostblocks/demo/nextcloud/`
- [ ] Review the `flake.nix` and `secrets.yaml` from the demo
- [ ] Have a secrets file ready (or create one using SOPS)

## Step 1: Add Flake Inputs

**Action**: Edit `/home/cody/.flake/flake.nix`

Add to `inputs`:
```nix
selfhostblocks.url = "github:ibizaman/selfhostblocks";
sops-nix.url = "github:Mic92/sops-nix";
```

**Why**: These provide the modules and utilities needed for self-hosting services.

---

## Step 2: Create SOPS Secrets Module

**Action**: Create `modules/selfhost/sops.nix`

**Purpose**: Sets up SOPS for encrypted secrets management.

**Key components**:
- Import `sops-nix.nixosModules.default`
- Set `sops.defaultSopsFile` to your secrets file path
- Configure age key file location

**Reference**: See `flake.nix` lines 173-176 in the demo.

---

## Step 3: Create SSL Certificate Module

**Action**: Create `modules/selfhost/ssl.nix`

**Purpose**: Manages SSL certificates (self-signed for development, or Let's Encrypt for production).

**Key components**:
- Create self-signed CA
- Generate wildcard certificates
- Configure certificate for nginx group

**Reference**: See `flake.nix` lines 92-103 in the demo.

---

## Step 4: Create LLDAP Module

**Action**: Create `modules/selfhost/lldap.nix`

**Purpose**: Lightweight LDAP server for user management.

**Key components**:
- Import `selfhostblocks.nixosModules.lldap` (if available) or configure manually
- Enable LLDAP service
- Configure domain, subdomain, ports
- Link secrets from SOPS

**Reference**: See `flake.nix` lines 61-72 in the demo.

---

## Step 5: Create Authelia Module

**Action**: Create `modules/selfhost/authelia.nix`

**Purpose**: SSO/OIDC provider that authenticates users via LLDAP.

**Key components**:
- Import `selfhostblocks.nixosModules.authelia`
- Enable Authelia service
- Configure domain, subdomain
- Link to LLDAP configuration
- Link all required secrets from SOPS

**Reference**: See `flake.nix` lines 125-155 in the demo.

---

## Step 6: Create Nextcloud Module

**Action**: Create `modules/selfhost/nextcloud.nix`

**Purpose**: Nextcloud server configuration.

**Key components**:
- Import `selfhostblocks.nixosModules.nextcloud-server`
- Import `selfhostblocks.nixosModules.nginx`
- Enable Nextcloud service
- Configure domain, subdomain, data directory
- Link admin password from SOPS
- Enable apps (preview generator, LDAP, SSO)

**Reference**: See `flake.nix` lines 34-51, 74-86, 157-170 in the demo.

---

## Step 7: Create Nextcloud SSO Meta-Module

**Action**: Create `modules/selfhost/nextcloud-sso.nix`

**Purpose**: Combines Nextcloud + LLDAP + Authelia for complete SSO setup.

**Key components**:
- Include SSL module
- Include LLDAP module
- Include Authelia module
- Include Nextcloud module
- Configure Nextcloud LDAP integration
- Configure Nextcloud SSO integration
- Optionally configure DNSmasq for local DNS

**Reference**: See `flake.nix` lines 89-171 in the demo.

---

## Step 8: Create Selfhost Meta-Module

**Action**: Create `modules/selfhost/selfhost.nix`

**Purpose**: Main entry point for all self-hosting services.

**Structure**:
```nix
{ FTS, ... }:
{
  FTS.selfhost = {
    description = "Self-hosting services";
    includes = [
      FTS.selfhost.sops
      FTS.selfhost.ssl
      FTS.selfhost.lldap
      FTS.selfhost.authelia
      FTS.selfhost.nextcloud
      FTS.selfhost.nextcloud-sso
    ];
  };
}
```

---

## Step 9: Set Up Secrets File

**Action**: Create and encrypt `secrets.yaml` using SOPS

**Required secrets** (based on demo):
- `nextcloud/adminpass` - Nextcloud admin password
- `lldap/user_password` - LLDAP admin password
- `lldap/jwt_secret` - LLDAP JWT secret
- `authelia/jwt_secret` - Authelia JWT secret
- `authelia/session_secret` - Authelia session secret
- `authelia/storage_encryption_key` - Authelia storage encryption key
- `authelia/hmac_secret` - Authelia HMAC secret
- `authelia/private_key` - Authelia private key
- `nextcloud/sso/secret` - Nextcloud SSO secret

**How to create**:
```bash
# Generate a random secret
nix run nixpkgs#openssl -- rand -hex 64

# Edit secrets.yaml with SOPS
SOPS_AGE_KEY_FILE=keys.txt nix run --impure nixpkgs#sops -- \
  --config sops.yaml \
  secrets.yaml
```

---

## Step 10: Use in Host Configuration

**Action**: Add to a host configuration file

**Example**: In `hosts/my-server.nix` or similar:
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

---

## Step 11: Configure DNS (Choose One)

### Option A: DNSmasq (Development)
Add DNSmasq configuration to your host to resolve domains locally.

### Option B: /etc/hosts (Testing)
Add entries to `/etc/hosts`:
```
127.0.0.1 n.example.com
127.0.0.1 ldap.example.com
127.0.0.1 auth.example.com
```

### Option C: Real DNS (Production)
Configure your DNS server to point domains to your server's IP.

---

## Step 12: Deploy and Test

1. **Build configuration**: `nix flake check`
2. **Switch to new configuration**: `sudo nixos-rebuild switch --flake .#hostname`
3. **Check services**: `systemctl status nextcloud lldap authelia`
4. **View logs**: `journalctl -u nextcloud -f`
5. **Access services**:
   - LLDAP: `https://ldap.example.com`
   - Authelia: `https://auth.example.com`
   - Nextcloud: `https://n.example.com`

---

## Troubleshooting

- **Secrets not decrypting**: Check SOPS key file permissions and location
- **Services not starting**: Check `journalctl -u service-name -f` for errors
- **SSL errors**: Accept self-signed certificates in browser, or use Let's Encrypt
- **DNS not resolving**: Check DNSmasq or `/etc/hosts` configuration
- **502 errors**: Wait for services to initialize (can take 1-2 minutes)

---

## Module Dependencies

```
nextcloud-sso
├── sops (secrets management)
├── ssl (certificates)
├── lldap (identity provider)
├── authelia (SSO provider)
└── nextcloud (main service)
    ├── nginx (reverse proxy)
    └── apps
        ├── ldap (LDAP integration)
        └── sso (SSO integration)
```

