# Adding a New Host

A host is **data** (a `den.hosts` entry) plus **an aspect** (`den.aspects.<name>`)
that includes fleet features. Conventions: [CLAUDE.md](../CLAUDE.md),
[den-conventions.md](den-conventions.md).

## 1. Hardware report

```bash
# on the target (or the beacon ISO: `just beacon`)
nix run github:numtide/nixos-facter#nixos-facter > facter.json
```

Put it at `hosts/<name>/facter.json`. `<fleet/hardware>` includes
`<fleet.hardware/facter>`, which reads `hosts/<hostname>/facter.json`.

## 2. Host file

```nix
# hosts/myserver/myserver.nix
{ __findFile, ... }:
{
  den.hosts.x86_64-linux.myserver = {
    description = "What this machine is for";
    users.cody = { };                    # users living on this host
    timeZone = "America/Los_Angeles";    # optional (null = UTC)
    deployment.ip = "192.168.0.50";      # optional; makes it deployable
    # deployment.sshUser = "root"; deployment.sshPort = 22;
    # settings.desktop.session = "gnome";                  # aspect settings
    # settings.cluster.k3s-agent.dedicatedTo = [ "pihole" ];
  };

  den.aspects.myserver.includes = [
    <fleet/hardware>                     # facter, audio, bluetooth, NetworkManager, …
    <fleet.hardware/nvidia>              # machine-specific leaves, as needed
    <fleet/desktop>
    <fleet/grub>
    (<fleet.disk/btrfs> { device = "/dev/nvme0n1"; withSwap = true; swapSize = "16"; })
  ];
}
```

- Machines of an existing kind include a role instead of a list
  (`den.aspects.nomad.includes = [ <fleet.roles/t2-laptop> ]`); add a role in
  `modules/roles/` when a second machine of a kind appears.
- Per-host knobs are **settings** on the entry (`settings.<aspect path>.*`),
  not function arguments. New entity keys must be declared in
  `modules/den/schema.nix` (strict mode rejects unknown keys).
- Larger host-only config goes in `hosts/<name>/<concern>.nix` as
  `den.aspects.<NAME>-<concern>` added to the includes; plain data in
  `hosts/<name>/_data/`.
- A user's config that only applies on this host:
  `den.aspects."cody@myserver".homeManager = …;`
- WSL: `wsl.enable = true;` on the entry (den's wsl battery).

## 3. Secrets

Host secrets live in the private nix-secrets repo as
`sops/hosts/<name>.yaml`, decrypted with the host's SSH key. Enroll the host
there (`just add-host <name> <ip>` inside `~/nix-secrets`), push, then
`just update-secrets` here.

## 4. Build and deploy

```bash
git add hosts/myserver                     # import-tree ignores untracked files
just build-host myserver
just install myserver -i <ip>              # fresh install via nixos-anywhere
just deploy myserver                       # later updates (deploy-rs)
nix eval --json .#deployTargets.myserver   # where deploy will connect
```
