# FTS Deployment Facet

The `FTS.deployment` facet provides everything needed to bootstrap and manage NixOS systems remotely, similar to skarabox but fully integrated with your FTS modules.

## Features

- **nixos-anywhere**: Headless NixOS installation
- **disko**: Declarative disk partitioning (integrates with FTS.system.disk)
- **nixos-facter**: Automatic hardware detection (via FTS.hardware.facter)
- **sops-nix**: Secrets management
- **Boot SSH**: Remote unlocking of encrypted drives during boot
- **WiFi Hotspot**: Bootstrap via WiFi when ethernet isn't available
- **Deployment**: deploy-rs or colmena for updates

## Quick Start

### 1. Configure a New Host

In your `hosts/<hostname>/<hostname>.nix`:

```nix
{
  FTS,
  __findFile,
  ...
}:
{
  den.hosts.x86_64-linux.myserver = {
    aspect = "myserver";
  };

  den.aspects.myserver = {
    description = "My remote server";
    includes = [
      # Deployment configuration
      (<FTS.deployment/config> {
        ip = "192.168.1.100";
        username = "admin";
        password = ./password.txt;  # Plain text, will be hashed
        sshPort = 22;
        
        # Optional: static IP (omit for DHCP)
        staticNetwork = {
          ip = "192.168.1.100";
          gateway = "192.168.1.1";
        };
      })
      
      # Boot SSH for remote unlocking
      <FTS.deployment/bootssh>
      
      # Disk configuration with encryption
      (<FTS.system/disk> {
        type = "btrfs-impermanence";
        device = "/dev/nvme0n1";
        withSwap = true;
        swapSize = "32";
      })
      
      # Desktop environment
      (<FTS.desktop> {
        environment.default = "gnome";
        displayManager.default = "gdm";
      })
      
      # Hardware detection
      <FTS.hardware>
      <FTS.kernel>
    ];
  };
}
```

### 2. Generate SSH Keys and Secrets

```bash
# Create host directory
mkdir -p hosts/myserver

# Generate SSH key for deployment
ssh-keygen -t ed25519 -f hosts/myserver/ssh -N ""

# Generate sops key (for secrets)
nix run nixpkgs#age -- -keygen -o hosts/myserver/age.key

# Create secrets file
cat > hosts/myserver/secrets.yaml <<EOF
# Encrypted secrets (edit with: nix run .#sops hosts/myserver/secrets.yaml)
user-password: mypassword
EOF

# Encrypt secrets with age
nix run nixpkgs#sops -- --encrypt --age $(cat hosts/myserver/age.key | grep public | cut -d: -f2 | tr -d ' ') hosts/myserver/secrets.yaml
```

### 3. Run Hardware Detection (Optional but Recommended)

If you have physical access to the target machine:

```bash
# On the target machine (booted from NixOS ISO or existing install)
nixos-facter > /tmp/facter.json

# Copy to your flake
scp target:/tmp/facter.json hosts/myserver/facter.json
```

### 4. Install NixOS with nixos-anywhere

```bash
# Install NixOS on the remote machine (will wipe disks!)
nix run github:nix-community/nixos-anywhere -- \
  --flake .#myserver \
  --ssh-key hosts/myserver/ssh \
  root@192.168.1.100
```

### 5. Deploy Updates

After the initial installation:

```bash
# Using deploy-rs
nix run .#deploy

# Or using colmena
nix run .#colmena deploy
```

### 6. Remote Unlocking (if using encryption)

If your disk is encrypted, unlock it remotely:

```bash
# SSH into boot environment (port 2223 by default)
ssh -p 2223 root@192.168.1.100

# Enter the disk encryption password when prompted
```

## Module Structure

```
FTS.deployment/
├── config         # Base deployment configuration
├── bootssh        # SSH access during initrd boot
├── hotspot        # WiFi hotspot for bootstrap
├── beacon         # ISO generation for installation
├── secrets        # sops-nix secrets management
├── vm             # VM generation for testing
├── iso            # ISO generation for any system
└── inputs         # Required flake inputs (informational)
```

## Integration with Other FTS Modules

### Disk Configuration

The deployment facet integrates seamlessly with `FTS.system.disk`:

```nix
# Single disk with BTRFS and impermanence
(<FTS.system/disk> {
  type = "btrfs-impermanence";
  device = "/dev/nvme0n1";
})

# ZFS with mirroring
(<FTS.system/disk> {
  type = "zfs";
  device = "/dev/nvme0n1";
  dataDevices = [ "/dev/sda" "/dev/sdb" ];  # Mirrored data pool
})

# Custom storage with mergerfs (for NAS)
{
  includes = [
    <FTS.hardware/storage>
    (<FTS.hardware/storage/nas> {
      drives = [ "/mnt/disk1" "/mnt/disk2" "/mnt/disk3" ];
      mergePath = "/mnt/storage";
    })
  ];
}
```

### Hardware Detection

The deployment config automatically uses `FTS.hardware.facter` when included:

```nix
<FTS.hardware>  # Includes facter, which provides hardware detection
```

### Secrets Management

Use sops for sensitive data:

```nix
# In your host configuration
<FTS.deployment/secrets>

# Then in your NixOS config
config.sops.secrets."user-password" = {
  neededForUsers = true;
};

# Reference the secret
users.users.myuser.hashedPasswordFile = config.sops.secrets."user-password".path;
```

## Advanced Usage

### Testing in VMs

Generate a VM version of any host for testing:

```nix
# In hosts/myserver/myserver.nix
{
  den.aspects.myserver = {
    includes = [
      # ... your normal configuration ...
      <FTS.deployment/vm>  # Add this to generate a VM
    ];
  };
}
```

Build and run the VM:

```bash
# Build the VM
nix build .#myserver-vm

# Run the VM (with 16 cores and 8GB RAM by default)
nix run .#myserver-vm

# SSH into the VM (port 2222 is forwarded to the VM's SSH port)
ssh -p 2222 root@localhost
```

The VM inherits the entire host configuration, including:
- Desktop environment
- Disk layout (as a virtual disk)
- All installed packages and services
- User accounts

This is perfect for testing changes before deploying to production!

### Generating Install ISOs

Create an ISO for any system configuration:

```nix
# In hosts/myserver/myserver.nix
{
  den.aspects.myserver = {
    includes = [
      # ... your normal configuration ...
      <FTS.deployment/iso>  # Add this to generate an ISO
    ];
  };
}
```

Build the ISO:

```bash
# Build the ISO
nix build .#myserver-iso

# Write to USB drive
sudo dd if=result/iso/*.iso of=/dev/sdX bs=4M status=progress
```

### Creating a Bootable ISO (Beacon)

For on-premise servers without network boot:

```nix
# In hosts/myserver/beacon.nix
{
  FTS,
  ...
}:
{
  den.aspects.myserver-beacon = {
    includes = [
      (<FTS.deployment/beacon> {
        ip = "192.168.1.100";
        username = "admin";
        sshAuthorizedKey = ../../hosts/myserver/ssh.pub;
      })
    ];
  };
}
```

Build the ISO:

```bash
nix build .#myserver-beacon
# Write to USB: dd if=result/iso/beacon.iso of=/dev/sdX bs=4M status=progress
```

### WiFi Hotspot Bootstrap

If you need to bootstrap over WiFi:

```nix
(<FTS.deployment/hotspot> {
  enable = true;
  ssid = "MyServer-Setup";
  passphrase = "temporary-password";
  ip = "192.168.50.1";
})
```

## Directory Structure Convention

```
hosts/
└── myserver/
    ├── myserver.nix         # Main host configuration
    ├── ssh                  # SSH private key (gitignored)
    ├── ssh.pub             # SSH public key
    ├── age.key             # Age private key (gitignored)
    ├── age.pub             # Age public key
    ├── secrets.yaml        # Encrypted secrets
    ├── facter.json         # Hardware detection (optional)
    └── known_hosts         # Known hosts file (auto-generated)
```

## Tips

1. **Always gitignore private keys**: Add `hosts/*/ssh`, `hosts/*/age.key`, etc. to `.gitignore`
2. **Use password files**: Instead of hardcoding passwords, use `password = ./password.txt;`
3. **Test in VMs first**: Use the beacon ISO to test installations in QEMU before physical deployment
4. **Keep secrets in sops**: Never commit plain-text secrets
5. **Use static IPs for servers**: Makes remote unlocking more reliable

## Troubleshooting

### SSH Connection Refused

- Ensure the target machine is booted and accessible
- Check firewall rules: `deployment.config` opens port 22 by default
- Verify SSH key permissions: `chmod 600 hosts/myserver/ssh`

### Cannot Unlock Encrypted Disk

- Check boot SSH is enabled: `<FTS.deployment/bootssh>` must be included
- Connect to boot environment: `ssh -p 2223 root@<ip>`
- Verify initrd networking works (DHCP or static IP configured)

### Hardware Not Detected

- Run `nixos-facter` on the target machine
- Place `facter.json` in `hosts/<hostname>/`
- Ensure `<FTS.hardware>` is included (which includes `FTS.hardware.facter`)

### Secrets Not Decrypting

- Verify sops keys are correctly generated
- Check `secrets.yaml` is encrypted with the correct key
- Ensure age key file exists and has correct permissions
- Run: `nix run nixpkgs#sops -- -d hosts/myserver/secrets.yaml` to test decryption

