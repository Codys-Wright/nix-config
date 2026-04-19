# Installing NixOS on a T2 MacBook

This runbook is for Intel MacBooks with the Apple T2 chip when you are:

- booting a `t2linux` live ISO instead of this repo's beacon installer
- SSHing into that live environment from another machine
- using `nixos-anywhere` from this flake
- preserving macOS and only formatting the Linux partitions

This matches hosts like [stowaway](/home/cody/.flake/hosts/stowaway/stowaway.nix) that use [`<fleet.disk/btrfs-partitions>`](/home/cody/.flake/modules/system/disk/btrfs-partitions.nix).

## Overview

The flow is:

1. Create the Linux partitions in macOS first.
2. Label those partitions so they match the host config.
3. Boot the t2linux live ISO.
4. Get the live ISO's IP address and enable SSH.
5. Run `just install <host> -i <live-ip> ...` from this repo on another machine.
6. After first boot, discover the installed system's real IP and update `fleet.deploy`.

## 1. Prepare the Host Config

Create the host config and stage it in git:

```bash
git add hosts/<hostname>/<hostname>.nix
```

`import-tree` only sees git-tracked files.

For T2 dual-boot hosts in this repo, the important part is usually the partition-label disk config:

```nix
(<fleet.disk/btrfs-partitions> {
  rootPartlabel = "stowaway-root";
  espPartlabel = "stowaway-esp";
  btrfsLabel = "stowaway";
  espLabel = "STOWAWAYESP";
})
```

That means the live install target must already contain GPT partitions labeled exactly:

- `stowaway-root`
- `stowaway-esp`

If those labels do not exist, `nixos-anywhere` will fail because this module formats only the named partitions and does not repartition the whole disk.

## 2. Boot the t2linux Live ISO

Boot the MacBook into the t2linux GNOME live ISO.

The t2linux NixOS guidance is here:

- https://wiki.t2linux.org/distributions/nixos/installation/
- https://wiki.t2linux.org/guides/preinstall

If you need Wi-Fi in the live environment, follow the t2linux firmware guidance first. Ethernet is simpler if you have it.

## 3. Find the Correct Disk and Partitions

On the live ISO, inspect the current disks and labels:

```bash
lsblk -e7 -o NAME,PATH,SIZE,TYPE,FSTYPE,FSVER,LABEL,PARTLABEL,MOUNTPOINTS
```

Also check the block IDs directly:

```bash
sudo blkid
```

And inspect the partlabel symlinks that this repo relies on:

```bash
ls -l /dev/disk/by-partlabel
```

For a host like `stowaway`, you want to see entries for:

```text
/dev/disk/by-partlabel/stowaway-root
/dev/disk/by-partlabel/stowaway-esp
```

If you are not sure which physical disk you are targeting, this is usually the clearest view:

```bash
lsblk -d -o NAME,PATH,SIZE,MODEL,SERIAL,TRAN
```

## 4. Verify or Set the Partition Labels

If the Linux partitions already exist but are missing labels, assign them before install.

Example for a root partition:

```bash
sudo parted /dev/nvme0n1 name 6 stowaway-root
```

Example for an EFI partition:

```bash
sudo parted /dev/nvme0n1 name 7 stowaway-esp
```

Re-check:

```bash
ls -l /dev/disk/by-partlabel
lsblk -e7 -o NAME,PATH,SIZE,TYPE,FSTYPE,LABEL,PARTLABEL
```

Do not guess partition numbers. Confirm them first with `lsblk` or `parted -l`.

## 5. Get the Live ISO IP Address

On the live ISO, find the current IP address:

```bash
ip -br addr
```

Often the shortest useful output is:

```bash
hostname -I
```

If you want the default-route interface too:

```bash
ip route get 1.1.1.1
```

Use the IP on the interface that your laptop can actually reach.

## 6. Enable SSH on the Live ISO

First, set the password for the live-session account you will SSH in as:

```bash
passwd
```

Then confirm that account actually has `sudo`:

```bash
sudo -v
```

If `sudo -v` succeeds, enable SSH in the live environment.

Make sure SSH is running on the live environment:

```bash
sudo systemctl enable --now ssh
```

If the live ISO uses `sshd` instead of `ssh`, use:

```bash
sudo systemctl enable --now sshd
```

Then confirm:

```bash
systemctl status ssh || systemctl status sshd
ss -lntp | rg ':22'
```

Before continuing, verify all three of these are known:

- the live ISO username
- the password you just set
- that `sudo` works for that user

From your workstation, test access:

```bash
ssh <live-user>@<live-ip>
```

## 7. Run the Install from This Repo

From `/home/cody/.flake` on your workstation:

```bash
just install <hostname> -i <live-ip> -u root --password <live-password>
```

Example:

```bash
just install stowaway -i 192.168.0.50 -u root --password hunter2
```

If the live ISO SSH daemon is on a non-default port:

```bash
just install <hostname> -i <live-ip> -u root -p <port> --password <live-password>
```

This repo's `just install` wrapper:

- defaults to `installer@<ip>` via `nixos-anywhere`
- supports `-u root` for live-ISO workflows
- installs `.#<hostname>`
- writes `hosts/<hostname>/facter.json`

The current wrapper is in [justfile](/home/cody/.flake/justfile).

## 8. Confirm the Installed System's Real IP

After rebooting into the installed NixOS system, SSH into the new host and discover the long-term address you actually want deploy-rs to use.

Useful commands on the installed machine:

```bash
ip -br addr
hostname -I
```

If Tailscale is enabled and that is the address you plan to deploy against:

```bash
tailscale ip -4
```

Pick one stable address:

- Tailscale IP, if this host will mostly be managed over Tailscale
- DHCP reservation address, if your LAN gives it a fixed lease
- static address, if you configure one explicitly

## 9. Update `fleet.deploy` in the Host Config

Set the actual deploy target in the host file:

```nix
(fleet.deploy { ip = "100.64.12.34"; })
```

For `stowaway`, that means editing:

- [hosts/stowaway/stowaway.nix](/home/cody/.flake/hosts/stowaway/stowaway.nix)

Do not leave a copied IP from another host in place.

## 10. Bootstrap Host Secrets for Future Deploys

After first boot, fetch the host key and rekey secrets:

```bash
scripts/bootstrap-host-secrets.sh -n <hostname> -d <installed-ip>
```

Example:

```bash
scripts/bootstrap-host-secrets.sh -n stowaway -d 100.64.12.34
```

That updates:

- `hosts/<hostname>/host_key.pub`
- `sops.yaml`
- relevant `secrets.yaml` files

For `just deploy <hostname>` to work later, you will also need:

- `hosts/<hostname>/secrets.yaml`
- `hosts/<hostname>/known_hosts`

## 11. Sanity Checklist

Before install:

- `hosts/<hostname>/<hostname>.nix` exists and is staged
- partition labels match the host config exactly
- the t2linux live ISO has network access
- SSH is running on the live ISO
- you know the reachable live ISO IP
- you know which live ISO user/password you are authenticating with

After install:

- the machine boots the installed NixOS system
- `hosts/<hostname>/facter.json` was generated
- `fleet.deploy.ip` is updated to the real installed-system IP
- host secrets/bootstrap is done before relying on `just deploy`
