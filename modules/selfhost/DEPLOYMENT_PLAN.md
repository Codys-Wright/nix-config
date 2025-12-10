# Server Deployment Module Plan

## Goal
Extract Skarabox's deployment and host management capabilities without the disk management (disko, ZFS encryption, etc.). Keep the flexible server configuration while adding easy deployment workflows.

## What We'll Extract from Skarabox

### ✅ Keep (Deployment & Management)
- Host management structure (`skarabox.hosts` → `FTS.deployment.hosts`)
- SSH key management per host
- SOPS secrets per host
- Known hosts file generation
- SSH commands (`ssh`, `boot-ssh`)
- Installation via `nixos-anywhere` (simplified, no disk encryption)
- Deployment via `colmena` or `deploy-rs`
- Host generation utilities (`gen-new-host`)

### ❌ Remove (Disk Management)
- Disk encryption passphrases
- ZFS pool management
- Disko disk formatting
- `unlock` command for ZFS
- Disk-specific secrets (`rootPassphrase`, `dataPassphrase`)
- Beacon ISO generation (optional - can keep if useful)

## Structure

```
modules/
  deployment/
    deployment.nix          # Main flake module (like skarabox flakeModules/default.nix)
    colmena.nix            # Colmena integration
    deploy-rs.nix          # Deploy-rs integration
    lib/
      gen-new-host.nix     # Generate new host structure
      ssh.nix              # SSH helper
      install.nix           # Simplified nixos-anywhere wrapper
      gen-knownhosts.nix   # Known hosts generation
```

## Host Configuration Structure

Instead of Skarabox's `skarabox.hosts`, we'll use:

```nix
FTS.deployment.hosts = {
  myserver = {
    ip = "192.168.1.100";
    system = "x86_64-linux";
    sshPort = 22;
    username = "root";  # or "nixos" for initial install
    
    # SSH keys (auto-generated or manual)
    sshPrivateKeyPath = "./hosts/myserver/ssh";
    sshAuthorizedKey = "./hosts/myserver/ssh.pub";
    
    # SOPS secrets
    secretsFilePath = "./hosts/myserver/secrets.yaml";
    sopsKeyPath = "./sops.key";  # Main SOPS key
    
    # Host key for known_hosts
    hostKeyPath = "./hosts/myserver/host_key";
    hostKeyPub = "./hosts/myserver/host_key.pub";
    knownHostsPath = "./hosts/myserver/known_hosts";
    
    # NixOS modules to include
    modules = [
      # Your existing host configuration
      ./hosts/myserver/myserver.nix
    ];
  };
};
```

## Generated Commands Per Host

For each host `myserver`, we'll generate:

- `nix run .#myserver-ssh` - SSH into the server
- `nix run .#myserver-install` - Install NixOS via nixos-anywhere
- `nix run .#myserver-sops` - Edit host's secrets.yaml
- `nix run .#myserver-gen-knownhosts` - Generate known_hosts file

## Deployment Commands

- `nix run .#deploy-rs` - Deploy all hosts via deploy-rs
- `nix run .#colmena` - Deploy all hosts via colmena
- `nix run .#gen-new-host <hostname>` - Generate new host structure

## Integration with Existing Structure

Your existing hosts use `den.hosts`:

```nix
den.hosts.x86_64-linux = {
  myserver = {
    description = "My server";
    users.cody = { };
    aspect = "myserver";
  };
};
```

We'll extend this to also work with `FTS.deployment.hosts`:

```nix
FTS.deployment.hosts = {
  myserver = {
    ip = "192.168.1.100";
    system = "x86_64-linux";
    modules = [
      # This will include your existing den.hosts configuration
      ./hosts/myserver/myserver.nix
    ];
  };
};
```

## Workflow

### 1. Generate New Host
```bash
nix run .#gen-new-host myserver
```

This creates:
- `hosts/myserver/ssh` (private key)
- `hosts/myserver/ssh.pub` (public key)
- `hosts/myserver/host_key` (host SSH key)
- `hosts/myserver/host_key.pub`
- `hosts/myserver/secrets.yaml` (encrypted)
- `hosts/myserver/known_hosts`
- Updates `FTS.deployment.hosts` config

### 2. Configure Host
Edit `hosts/myserver/myserver.nix` with your configuration (using your existing den/FTS structure).

### 3. Install NixOS
```bash
# On a server booted with any Linux (or NixOS installer ISO)
nix run .#myserver-install
```

### 4. Deploy Updates
```bash
# Via deploy-rs
nix run .#deploy-rs

# Or via colmena
nix run .#colmena
```

### 5. SSH Access
```bash
nix run .#myserver-ssh
```

## Implementation Steps

1. ✅ Create `modules/deployment/deployment.nix` - Main flake module
2. ✅ Create `modules/deployment/lib/gen-new-host.nix` - Host generation
3. ✅ Create `modules/deployment/lib/ssh.nix` - SSH helper
4. ✅ Create `modules/deployment/lib/install.nix` - Installation wrapper
5. ✅ Create `modules/deployment/lib/gen-knownhosts.nix` - Known hosts
6. ✅ Create `modules/deployment/colmena.nix` - Colmena integration
7. ✅ Create `modules/deployment/deploy-rs.nix` - Deploy-rs integration
8. ✅ Add flake inputs (nixos-anywhere, deploy-rs, colmena)
9. ✅ Create justfile commands
10. ✅ Test with existing host

## Key Differences from Skarabox

1. **No disk management** - You handle disk setup yourself
2. **Simpler installation** - Just `nixos-anywhere`, no disk encryption keys
3. **Flexible configuration** - Use your existing den/FTS structure
4. **Optional beacon** - Can skip ISO generation if not needed
5. **Integration** - Works alongside your existing host definitions

