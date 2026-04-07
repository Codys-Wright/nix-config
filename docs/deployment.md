# Deployment Guide

This guide covers the three deployment workflows: testing in a VM, installing on new hardware, and pushing updates to running hosts.

## Quick Reference

| Command | What it does |
|---|---|
| `just beacon-vm` | Boot the beacon installer ISO in a QEMU VM |
| `just install <host> -i <ip> -p <port>` | Install a host onto a machine running the beacon |
| `just deploy <host>` | Push config updates to a running host via deploy-rs |
| `just switch` | Apply config locally (current machine) |

---

## 1. Test an Install in a VM

This lets you practice the full install workflow without touching real hardware.

### Start the beacon VM

```bash
just beacon-vm
```

This boots a QEMU VM with:
- The beacon installer ISO
- A 40GB virtual disk (for the install target)
- SSH forwarded on port 2222
- A GTK window (use `--no-gui` for headless)

The beacon displays a random password and connection info on screen.

### SSH into the beacon (optional)

```bash
ssh -p 2222 -o StrictHostKeyChecking=no installer@localhost
```

Use this to inspect disks (`lsblk`), test networking, etc.

### Install a host onto the VM

From your laptop/host machine (not inside the VM):

```bash
just install THEBATTLESHIP -i localhost -p 2222 --password <beacon-password>
```

**Arguments:**
- `THEBATTLESHIP` — the host config to install (must have a disk config)
- `-i localhost` — IP/hostname of the beacon (localhost since VM forwards ports)
- `-p 2222` — SSH port (VM forwards 2222 → 22)
- `--password <word1-word2-word3>` — the random password shown on the beacon screen (or use SSH keys)

This runs `nixos-anywhere` which:
1. SSHs into the beacon VM
2. Partitions the virtual disk using the host's disko config
3. Installs the NixOS configuration
4. Generates `hosts/<hostname>/facter.json` for hardware detection
5. Reboots

**Note:** The host needs a disk config in its includes:
```nix
(<fleet.system/disk> {
  type = "btrfs-impermanence";
  device = "/dev/vda";  # virtio disk in QEMU
})
```

---

## 2. Install on Real Hardware

### Build the beacon ISO

```bash
just beacon
```

The ISO is at `result/iso/beacon.iso` (~1.4GB).

### Write to USB

```bash
just beacon-usb
```

Or manually:
```bash
sudo dd if=result/iso/beacon.iso of=/dev/sdX bs=4M status=progress
```

### Boot the target machine

1. Boot from the USB
2. The beacon shows: hostname, IP address, password, and a QR code
3. WiFi is available via `iwctl` if needed

### Install from your laptop

```bash
just install <hostname> -i <beacon-ip>
```

For example:
```bash
just install THEBATTLESHIP -i 192.168.0.50
```

If using the beacon's password instead of SSH keys:
```bash
just install THEBATTLESHIP -i 192.168.0.50 --password apple-banana-cherry
```

The machine reboots into the installed system when done.

---

## 3. Push Updates to a Running Host

After a host is installed and running, push config changes with deploy-rs.

### Prerequisites

The host needs `fleet.deploy` in its includes with a reachable IP:

```nix
(fleet.deploy { ip = "100.74.250.99"; })  # tailscale IP
```

And an SSH private key stored in SOPS at:
```
hosts/<hostname>/secrets.yaml → ['<hostname>']['system']['sshPrivateKey']
```

### Deploy

```bash
just deploy THEBATTLESHIP
```

This:
1. Extracts the SSH key from SOPS
2. Builds the new system configuration
3. Copies it to the remote host
4. Activates it with automatic rollback (reverts if SSH breaks)

To disable rollback (needed for SSH/network config changes):
```bash
just deploy THEBATTLESHIP --no-rollback
```

### Apply locally instead

If you're on the machine itself:
```bash
just switch
```

---

## 4. Create a New Deployable Host

### 1. Create the host file

```
hosts/<hostname>/<hostname>.nix
```

```nix
{ fleet, __findFile, ... }:
{
  den.hosts.x86_64-linux.<hostname> = {
    users.cody = {};
    aspect = "<hostname>";
  };

  den.aspects.<hostname> = {
    includes = [
      # Desktop
      (fleet.desktop { default = "niri"; })
      (fleet.grub { uefi = true; })
      (fleet.hardware {})

      # Disk — update device to match target hardware
      (<fleet.system/disk> {
        type = "btrfs-impermanence";
        device = "/dev/nvme0n1";
      })

      # Deploy target
      (fleet.deploy { ip = "100.74.250.99"; })

      # Apps & coding
      <fleet/apps>
      (fleet.coding {
        editor = { default = "nvf"; };
        terminal = { default = "ghostty"; };
        shell = { default = "nushell"; };
      })
    ];

    nixos = { ... }: {
      time.timeZone = "America/Los_Angeles";
    };
  };
}
```

### 2. Git add the file

```bash
git add hosts/<hostname>/<hostname>.nix
```

import-tree only sees git-tracked files.

### 3. Install via beacon

```bash
just beacon-vm                                    # or boot real hardware from USB
just install <hostname> -i <ip> -p <port>
```

### 4. Deploy updates

```bash
just deploy <hostname>
```

---

## 5. Test with MicroVM

For quick local testing without the full beacon workflow:

```nix
# In hosts/<hostname>/microvm.nix
{ fleet, __findFile, ... }:
{
  den.hosts.x86_64-linux.<hostname>-vm = {
    users.cody = {};
    aspect = "<hostname>-vm";
  };

  den.aspects.<hostname>-vm = {
    includes = [
      (fleet.system._.microvm { graphics = true; })
      <fleet.desktop/environment/niri>
      (fleet.coding {
        editor = { default = "nvf"; };
        terminal = { default = "ghostty"; };
        shell = { default = "fish"; };
      })
    ];
  };
}
```

Then:
```bash
nix run .#<hostname>-vm
```

Login: username = password (e.g., `cody` / `cody`). SSH: `ssh -p 2222 root@localhost` (password: `root`).
