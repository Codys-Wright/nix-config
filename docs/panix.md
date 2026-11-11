# Panix beside deploy-rs

Stage 1 of moving this fleet's deploys to [Panix](https://github.com/mihakrumpestar/panix)
(v0.12.0, AGPL-3.0, docs at panix.xyz). Panix is **added** next to deploy-rs.
deploy-rs, `just deploy`, `just switch` and sops-nix are unchanged. Nothing in
this stage touched a real host except read-only `panix … --dry-run-with-inspect`
against THEBATTLESHIP itself. Every claim below about behaviour was either run
on a throwaway QEMU VM (section 6 has the exact runs) or read in Panix's source
at tag `v0.12.0` (commit `4265351`); each says which.

## 1. The rollback finding

**Panix's "opt-in auto rollback" is not deploy-rs's magic rollback.
It does not protect a remote host from a config that breaks its own sshd or
network. That is a regression for every remote host, and for a VPS.**

- **What deploy-rs does:** `activate-rs` runs `nix-env --set` and the
  activation on the target. Then it creates a canary file and waits 30 s for
  the deployer to delete it over a **new** SSH connection. If no confirmation
  arrives, the **target itself** rolls back (`nix-env --rollback` +
  re-activate). Source: deploy-rs `src/bin/activate.rs`, `activate()` and
  `activation_confirmation()`.
- **What Panix does:** it rolls back only when `switch-to-configuration` exits
  non-zero. Source: `internal/workflow/activate/handler.go`, `executeActivation()`
  → `autoRollbackToPreviousGeneration()`. It re-runs `nix-env --set <previous
  closure>` and `switch-to-configuration switch` over the deployer's SSH
  session. There is no confirmation step, no target-side timer, and no check
  that a new connection still works.
- **On the VM (section 6):**

  | Deploy | Panix | deploy-rs |
  |---|---|---|
  | moves sshd to port 2200 | **reported success, no rollback, host unreachable** | rolled back after 30 s, host reachable |
  | firewall stops admitting 22 | **reported success, no rollback; still locked out after a hard reset** (bad generation is the boot default) | rolled back after 30 s, host reachable |
  | a unit fails, so switch exits 4 | auto-rolled back to the previous closure | (auto-rollback; not re-tested) |
  | link dies mid-activation | **split host** (see below) | not tested |

  Panix's SSH session also multiplexes through a ControlMaster. A Panix
  post-activation hook that "checks SSH" rides the already-open connection
  and succeeds even when new connections are refused.
- **Link loss mid-activation:** Panix runs `switch-to-configuration` directly
  in the SSH session, not under `systemd-run`. Killing Panix and its SSH
  master 8 s into a 30 s activation left the VM split:
  - the boot profile pointed at the new generation;
  - `/etc` was already switched;
  - `/run/current-system` and the running services were still the old system;
  - the activation never finished, and nothing rolled back.

  The next reboot boots the half-applied generation. Killing only the Panix
  process (master alive) let the activation finish.
- **What this PR adds to close the gap (proven on the VM, not on a real
  host):** a dead-man switch.
  - The generated `panix.yml` gives every NixOS host a `pre` activation hook.
    It arms a target-side `systemd-run` timer (300 s) that runs
    `nix-env --switch-generation <pre-deploy gen>` + `switch-to-configuration switch`.
  - `just panix-deploy` disarms that timer afterwards over a **fresh**
    connection (`ControlPath=none`).
  - On the VM, the sshd-breaking and firewall-breaking deploys both reverted
    themselves about 60 s after the failed disarm (60 s window in the lab).
  - It does **not** cover:
    - a reboot inside the window (the transient timer is lost);
    - an activation that hangs past the window;
    - the link-loss split above. That run had no hook; with the hook armed
      nobody would disarm it, so the timer should fire and switch back, but
      this was not tested.
  - A bare `panix deploy` without the disarm is reverted after 300 s. Use
    `just panix-deploy`, or disarm by hand with `just panix-confirm <host>`.

**Would I trust Panix alone on a remote machine I cannot reach physically?
No.** Plain Panix (v0.12.0) can turn a bad sshd/firewall/network change into a
lost machine, and reports it as a success. With this PR's dead-man hook and
`just panix-deploy`, the two lock-out cases tested recovered by themselves on a
VM. That's better, but it is unproven on real hardware, it doesn't cover the
cases listed above, and it's a wrapper this fleet would maintain, not a
Panix feature. For a VPS with a provider console, Panix + dead-man is
defensible. Without a console, keep deploy-rs's magic rollback for updates.

## 2. Recommendation

**Not yet as a replacement. Yes as a bootstrap tool and as an opt-in second
deployer.**

- **Bootstrap (installer → disko → nixos-install → reboot): it worked.** It
  was fast (24 s in the lab) and shows each command, and it can place a
  pre-generated host key during install (section 5). That beats today's
  `just install` path, which disables host-key checking.
  - The **kexec** path (bootstrapping from a provider's Debian/Ubuntu image,
    the usual VPS case) was **not tested**. Only the "already in a NixOS
    installer" path was.
- **Updates to remote hosts: keep deploy-rs** until Panix has a target-side
  confirm/rollback, or until the dead-man wrapper has a track record on a
  physically reachable host (stage 2 below).
- **Maturity:** v0.x, one maintainer, a thesis project. It's careful code with
  good unit tests, but three Panix rough edges turned up in one afternoon:
  - the eval theme bug;
  - the timeout reported as "not found";
  - the misleading plain `--dry-run`.

  The tag-overlap trap (section 6.5) is a fourth, but it's documented
  behaviour that my lab manifest set up. Section 9 has the full list.

## 3. What this PR adds

| File | What |
|---|---|
| `modules/deployment/panix.nix` | Flake input `github:mihakrumpestar/panix/v0.12.0` (nixpkgs follows), `packages.<system>.panix`, aspect `fleet.deployment._.panix` (Panix + GNU rsync in a home) |
| `users/cody/cody.nix` | includes `<fleet.deployment/panix>`, so Panix is in cody's home on THEBATTLESHIP and voyager. airlock has no den user, so it gets Panix through `nix develop` only |
| `modules/flake/devShells.nix` | `panix` + `rsync` in the `default` and `deploy` dev shells |
| `modules/flake/panix-manifest.nix` | Generates `panix.yml` from `den.hosts.*.*.deployment` (via `deployTargets`, the same data deploy-rs reads). Adds `nix run .#write-panix-manifest` and `checks.<system>.panix-manifest`, which **fails when the committed file is stale** (tested both ways) |
| `panix.yml` | Generated. THEBATTLESHIP, electric, nomad, stowaway (`nixosConfigurations`), airlock (`darwinConfigurations`), beacon listed but `disabled` |
| `justfile` | `panix-plan [host]`, `panix-deploy <host>`, `panix-confirm <host>`, `panix-rollback <host> [--gen=N]`. Nothing in CI or timers calls them |
| `docs/panix.md` | This file |

Safety choices in the generated manifest (each is commented in the generator):

- `auto_rollback: true`.
- The dead-man hook on NixOS installables.
- **No `bootstrap:` section on any real host.** Panix's Inspect refuses to
  bootstrap a machine without bootstrap SSH, so a real host found in an
  installer fails Inspect instead of being wiped.
- `beacon` disabled: it is the installer ISO, which is exactly what Panix
  treats as "bootstrap me".
- `local_machine_hostname: panix-no-local-machine`. Panix runs commands
  without SSH, locally, when a machine's hostname equals this machine's
  hostname; the sentinel means it never matches.
- `runtime.flake_validation_timeout: 15m`. THEBATTLESHIP's toplevel takes about
  70 s to evaluate. At the 60 s default Panix reports the output "not found in
  flake", which is misleading.
- `tui.theme: panix` works around a v0.12.0 `panix eval` bug ("theme name must
  not be empty", fixed upstream in `bebad67`, after the tag).
- Secrets: none.

The recipes:

- **`just panix-plan [host]`**: no host gives a config-only `--dry-run`; a
  host adds Panix's read-only Inspect (section 4). Prints every command,
  de-duplicated.
- **`just panix-deploy <host>`**:
  - refuses unknown or disabled hosts and a stale `panix.yml`;
  - prints the live system and generation;
  - asks you to type the host name;
  - deploys, disarms the dead-man over a fresh SSH connection and prints the
    live generation again;
  - if the fresh connection fails, says the host will revert within 300 s.
- **`just panix-rollback <host> [--gen=N]`**: confirms, then
  `panix rollback -t <host>` with before/after.

## 4. What Panix does, phase by phase

Every remote command is `ssh -o LogLevel=ERROR -l <user> -p <port>
[-i <key> -o IdentitiesOnly=yes] -o ControlMaster=auto
-o ControlPath=~/.cache/panix/ssh/%C -o ControlPersist=60
-o UserKnownHostsFile=<file> -o StrictHostKeyChecking=accept-new <host> '<argv…>'`.

- **User:** the manifest's SSH user. That's root for every NixOS host here,
  the same as deploy-rs. System-level commands get `sudo` prepended only when
  the SSH user is not root (airlock's `rat`), and that sudo must be
  passwordless.
- **Identity:** your ssh-agent or `~/.ssh/config`. Panix never reads sops.
  deploy-rs's wrapper decrypts a per-host deploy key from nix-secrets; Panix
  doesn't.

The commands below were captured from `just panix-plan THEBATTLESHIP` and the VM
runs:

| Phase | Where | Exact commands | Writes on the target |
|---|---|---|---|
| Inspect | target | `echo OK`, `uname -m`, `uname -s`, `id -u`, `cat /etc/os-release` (twice), `uname -r`, `env NIX_PAGER=cat nix-env --profile /nix/var/nix/profiles/system --list-generations` | nothing |
| Bootstrap (only if `/etc/os-release` says `VARIANT_ID=installer`, or non-NixOS → kexec, **and** bootstrap SSH is configured) | local + target | local `nix build …#nixosConfigurations.<h>.config.system.build.diskoScript`; `nix copy --to ssh-ng://root@<h>?ssh-key=… --no-check-sigs <diskoScript>`; target runs `<diskoScript>` (disko destroy+format+mount, **no prompt**) | wipes and formats the disks |
| Build | local | `env XDG_CACHE_HOME=~/.cache/panix/<flake>/<type>/<name> nix --extra-experimental-features 'nix-command flakes' build --no-link --print-out-paths --keep-going .#nixosConfigurations.<h>.config.system.build.toplevel` | — |
| Transfer | local → target | `nix copy --to ssh-ng://root@<h>:22 --no-check-sigs <closure>` (bootstrap: `…?remote-store=local?root=/mnt`) | store paths |
| Secrets (only with `secrets:` entries; none in this fleet's manifest) | local → target | `rsync -rcEx --mkpath --perms --chmod=… --chown=uid:gid <local> <h>:<remote>` (bootstrap: `/mnt` prefix), or a command's stdout staged + renamed | the secret files |
| Activate (installed host) | target | pre hooks (`env PANIX_…=… sh -c '<hook>'`), `nix-env --profile /nix/var/nix/profiles/system --set <closure>`, `<closure>/bin/switch-to-configuration switch`, post hooks | new generation, the switch |
| Activate (bootstrap) | target | `sh -c 'command -v -- nixos-install'`, `nixos-install --no-root-passwd --no-channel-copy --system <closure> --root /mnt`, `readlink -f /mnt/nix/var/nix/profiles/system` (must equal the closure, else no reboot), `reboot` | the installed system |
| Rollback (auto or `panix rollback`) | target | `readlink /nix/var/nix/profiles/system-<N>-link`, `nix-env --profile … --set <that closure>`, `<that closure>/bin/switch-to-configuration switch` | a **new** generation pointing at the old closure; the failed generation stays in the list and the boot menu |

Compared with the tools in use today:

- **deploy-rs** (remote, `nix run .#deploy-rs` / `just deploy`):
  - builds a wrapper profile (`activatable-nixos-system-…`) locally;
  - copies it with `nix copy --substitute-on-destination` unless
    `fastConnection`;
  - on the target, runs `activate-rs activate` as root: `nix-env -p … --set`,
    then `deploy-rs-activate` (switch-to-configuration), then the canary wait;
  - rolls back on the target with `nix-env --rollback`, which deletes the
    failed generation.
- **`nh os switch`** (`just switch`) builds and activates on the local machine
  with sudo. There's no network in the loop, so neither the lock-out nor the
  link-loss case applies.
- **nixos-rebuild-ng** wraps `switch-to-configuration` in `systemd-run` so a
  dropped session can't kill it (upstream behaviour, not re-verified here).

Things Panix does **not** do to the target: it doesn't touch `nix.conf`,
substituters or trusted users. `--extra-experimental-features` is passed on
the local nix commands only. `nix copy --no-check-sigs` relies on the SSH user
being a trusted Nix user, which root is.

**Dry-run caveat:** plain `--dry-run` connects to nothing and assumes every
machine is unbootstrapped (`RequiresKexec`). For an installed host it previews
a copy into `/mnt` and then fails with "target is not a NixOS installer". Use
`--dry-run-with-inspect` (what `just panix-plan <host>` does). Hooks are logged,
not run, in both dry-run modes; verified on THEBATTLESHIP, where no
`panix-deadman` unit appeared.

## 5. Bootstrap

This section stands on its own; the VPS thread can work from it.

**Proven on the VM:**

1. A blank 8 GB disk and the NixOS installer ISO with a throwaway key on root.
2. One `panix deploy` with a `bootstrap:` section did, in 24 s:
   - Inspect: `VARIANT_ID=installer` → not bootstrapped;
   - build and copy `diskoScript`, run it (GPT + BIOS boot + ext4 on
     `/dev/vda`);
   - build the toplevel and `nix copy` it into `/mnt`;
   - `nixos-install --system … --root /mnt` (GRUB installed on `/dev/vda`);
   - verify `/mnt/nix/var/nix/profiles/system` resolves to the built closure,
     then `reboot`.
3. The VM came up from disk as the configured system, generation 1.
4. Re-bootstrapping the same disk from the ISO again (the rescue path after
   a lock-out) also worked. It wiped the disk and the generation history with
   **no confirmation**: when the target is an installer, `allow_destructive_actions`
   isn't needed. Only `force_bootstrap` on an installed system needs it.

The manifest used (`url` and paths from the lab):

```yaml
fleet:
  auto_rollback: true
  flakes:
    lab:
      url: path:/tmp/panix-research/labflake
      installables:
        nixosConfigurations:
          labvm:
            machines:
              labvm:
                ssh:          { hostname: 127.0.0.1, port: 2222, username: root,
                                identity_file: …/lab_key, known_hosts_file: …/lab_known_hosts }
                bootstrap:
                  ssh:        { hostname: 127.0.0.1, port: 2222, username: root,
                                identity_file: …/lab_key }
```

Notes for doing this on a real machine:

- **The config must import disko and define `disko.devices`**: Panix builds
  `config.system.build.diskoScript`. This fleet's `fleet.system._.disk._.btrfs`
  aspect does that.
- **Bootstrap SSH must be root.** Panix's docs say non-root bootstrap isn't
  end-to-end supported.
- **Host keys:**
  - bootstrap SSH uses a temporary known_hosts (TOFU per session);
  - regular SSH uses `known_hosts_file` with `accept-new`;
  - the installed system has new host keys unless you supply them (below),
    so a stale known_hosts entry for the same `host:port` makes the first
    regular connection fail with "REMOTE HOST IDENTIFICATION HAS CHANGED".
- **After bootstrap, remove the `bootstrap:` section.** Inspect errors when
  bootstrap SSH is configured on a bootstrapped machine. Use two manifests or
  delete it after install.
- **Kexec from Debian/Ubuntu (a VPS's stock image) was not tested.**
  - Panix fetches `nixos-kexec-installer-noninteractive-<arch>-linux.tar.gz`
    from nix-community/nixos-images `latest`. Pin `bootstrap.kexec.image` for
    reproducibility.
  - It needs about 1 GB RAM.
  - It reconnects on `kexec.ssh_port`.

**What a failure leaves** (from the source and the runs):

| Fails in | State left |
|---|---|
| Inspect | nothing changed |
| disko build or copy | nothing changed on the target's disks |
| disko run | disks partly or fully wiped; the installer is still running, so re-run the bootstrap |
| closure copy / secrets | disks formatted, `/mnt` partly populated; re-run |
| `nixos-install` | as above, no reboot; re-run |
| profile check (readlink ≠ closure) | Panix refuses to reboot; re-run |
| after reboot, the new system doesn't come up | **no rollback exists** (no previous generation); console or rescue boot only |

**First install of a host that needs its age key (sops-nix):**

- **How this fleet does it today:**
  - hosts decrypt with their SSH host key (`ssh-to-age` of
    `/etc/ssh/ssh_host_ed25519_key`, e.g. `hosts/THEBATTLESHIP/sops.nix`);
  - a host is enrolled after it exists: `just add-host <name> <ip>` inside
    `~/nix-secrets` (reads the live host key), push, then `just update-secrets`
    here, then redeploy (`docs/add-new-host.md`, `docs/managing-secrets.md`);
  - until then sops-nix can't decrypt on the new host;
  - this works the same with Panix.
- **A Panix-native alternative, proven with a throwaway key:**
  - a `secrets:` entry on the machine, present during bootstrap, is written
    under `/mnt` **before** `nixos-install`;
  - the lab VM placed a pre-generated
    `/etc/ssh/ssh_host_ed25519_key` (0600 root) and `.pub` (0644);
  - the installed system served exactly that key on first boot, and its
    `ssh-to-age` recipient matched the one derived from the local `.pub`;
  - so the recipient can be enrolled in nix-secrets **before** install, and
    sops-nix decrypts on first activation.
  - Commands rsync'd:
    `rsync -rcEx --mkpath --perms --chmod=D700,F600 --chown=0:0 <key> <h>:/mnt/etc/ssh/ssh_host_ed25519_key`.
  - Doing this for real means generating a host private key off-host and
    feeding it to Panix (e.g. `command: sops -d --extract …`). That is a real
    secret passing through Panix's secrets phase, so it's a Keeper/owner
    decision; it wasn't done here.
  - `nixos-anywhere --extra-files` is the existing equivalent.
  - Keep that entry in a bootstrap-only manifest.

## 6. The VM proof

Setup:

- A throwaway flake at `/tmp/panix-research/labflake`, outside this repo:
  - disko `725ea35` (the fleet's pin) and nixpkgs `bd3bac8` (25.05). That's
    **not** the fleet's nixpkgs (`e62746b`, 26.11): I took the wrong lock
    node. Panix's commands don't depend on it, but `switch-to-configuration`
    was 25.05's;
  - deploy-rs at the fleet's pinned rev `cf64c8c`.
- The lab system (`labvm`): GRUB BIOS, disko ext4, `PermitRootLogin
  prohibit-password`, password auth off, firewall on, the lab key on root.
- QEMU/KVM, 2 GB, 2 vCPU, user-mode net, `127.0.0.1:2222 → 22` (plus
  `2223 → 2200` as a side door for recovery), QEMU monitor socket.
- Panix v0.12.0 from this PR's input, console output mode.
- All VMs were killed and their disks deleted afterwards. Logs and scripts
  remain in `/tmp/panix-research/run/`.

| # | What | Result |
|---|---|---|
| 1 | Bootstrap blank disk from the installer ISO | success in 24 s, see section 5 |
| 2 | Trivial change (`/etc/panix-lab-marker`, `hello`) | success in 6 s, generation 2 |
| 3 | `labvm-failunit` (a unit that exits 1) | switch exited 4. Panix: "auto-rollback succeeded: activation failed: exit status 4". Marker back to v2. Generations: 3 = broken, 4 = the v2 closure again (current) |
| 4 | `labvm-nossh` (sshd on 2200) | **Panix rc=0, all phases green, no rollback; port 22 dead**, sshd listening on 2200 |
| 5 | Recovery through the side door with `panix rollback -t labvm` | see 6.5 below; then `panix rollback -t labvm-v2 --gen=4` through port 2223 restored v2 |
| 6 | `labvm-nofw --activation-mode test` (firewall drops 22) | rc=0, locked out; QEMU `system_reset` booted the old generation (test mode doesn't touch the boot profile), reachable again |
| 7 | `labvm-nofw` (switch) | **rc=0, locked out; still unreachable 150 s after a reset**: the broken generation is the boot default. Recovered only by booting the ISO and re-bootstrapping (wipes the disk) |
| 8 | deploy-rs, `labvm-nossh` | "Activation succeeded", then "Timeout elapsed for confirmation" → "Removing generation by ID 3", re-activated the last generation; reachable on 22, rc=1 |
| 9 | deploy-rs, `labvm-nofw` | same: rolled back after 30 s, reachable, rc=1 |
| 10 | Panix + dead-man hook, trivial change | armed, disarmed over a fresh connection, generation kept |
| 11 | Panix + dead-man, `labvm-nossh` | Panix rc=0; disarm failed (fresh connection refused); about 60 s later the timer ran `nix-env --switch-generation 3 && switch-to-configuration switch`; reachable, marker v2 |
| 12 | Panix + dead-man, `labvm-nofw` | same: reverted by itself, reachable |
| 13 | SIGKILL the Panix process 8 s into a 30 s activation | the activation **finished** (the SSH ControlMaster kept the session) |
| 14 | SIGKILL Panix **and its SSH master** 8 s in (simulated link loss) | **split host**: profile → new generation, `/etc` switched, `/run/current-system` and services still old, activation never finished, no rollback |
| 15 | Bootstrap with a pre-generated host key in `secrets:` | installed system served that key; `ssh-to-age` recipient matched |

**6.5 Tag-overlap trap.** In the lab, five installables shared machine `labvm`,
so `-t labvm` selected all five. Panix ran five rollbacks **on the same machine
concurrently**: there is no per-host lock. Four failed (`switch-to-configuration`
exit 11, its lock), and one re-activated the sshd-breaking generation.

My lab manifest set this up. The fleet manifest lists each host once and
`just panix-*` select a single host. **Never list one host under two
installables** in this fleet's manifest (the generator's comment says so).

## 7. Secrets

- The fleet's `panix.yml` has **no `secrets:` entries**. `panix secrets` and
  the Secrets phase are unused.
- sops-nix is unchanged. It decrypts on the host at activation with the host's
  key, and needs nothing from the deployer.
- **No conflict:**
  - Panix's secrets phase only rsyncs or streams files to the paths you list
    (outside the Nix store);
  - sops-nix writes `/run/secrets*`;
  - they'd only collide if someone pointed a Panix secret at a sops-nix path.
- Panix's own docs recommend sops-nix/agenix for NixOS and reserve their
  secrets phase for bootstrap material and non-NixOS targets.
- **Recommendation: keep sops-nix and don't use Panix's secrets phase**,
  except possibly the bootstrap host-key placement in section 5, which is the
  owner's/Keeper's call.

## 8. Fit with this repo

- **Outputs:**
  - `nixosConfigurations.<host>` and `darwinConfigurations.<host>` are used
    unmodified. Den names them exactly after `den.hosts` keys, and Panix's
    default attribute path (`<type>.<name>.config.system.build.toplevel` /
    `.system`) resolves.
  - Nothing in den's output generation got in the way except evaluation time
    (THEBATTLESHIP about 70 s, past the 60 s probe default, which Panix reports
    as "not found").
  - `url: .` evaluates the git tree, so untracked files are invisible, as
    everywhere in this repo.
- **home-manager** comes with each NixOS/darwin system (HM as a module). The
  standalone `homeConfigurations` aren't in the manifest (Panix could deploy
  them).
- **Shared builds:** no host here shares a build. Every host has its own
  configuration (nomad and stowaway share a role, not a toplevel). So Panix's
  "build once, deploy many" doesn't apply today.
- **Coverage:**
  - The manifest covers every host with a `deployment.ip`: the NixOS hosts
    deploy-rs covers (THEBATTLESHIP, electric, nomad, stowaway, beacon, the
    last disabled) plus airlock as darwin.
  - voyager has no `deployment` entry, so it isn't in either tool.
  - `THEBATTLESHIP-vm` (microvm) isn't a deploy target.
- **Data issue:** nomad and stowaway both have `deployment.ip = 192.168.0.139`,
  so one is stale. Deploying either by IP could hit the wrong laptop.
  `just panix-deploy` prints the IP before asking, but fix the den data
  before stage 2.
- **Darwin (airlock):**
  - Panix's preset is `nix-env --set` + `<closure>/activate` via sudo as
    `rat`; that needs passwordless sudo;
  - not tested: there's no darwin lab, and a real activation is out of scope;
  - upstream issue #28 ("Inspect fails on darwinConfigurations") was closed in
    Oct;
  - today's `just deploy-darwin` builds on the Mac with password SSH.
- **Stale `just deploy`** (not changed, hard limit): it reads
  `hosts/<host>/secrets.yaml` with `sops.yaml`, and neither exists any more.
  The working deploy-rs path is `nix run .#deploy-rs -- …`, whose wrapper
  reads `~/nix-secrets`. Not run here, since it decrypts a key.

## 9. Build location, caches, maturity, licence

- **Builds happen locally and are copied, like today:**
  - `build_mode: local`, then `nix build` on the control host with your nix
    config, so the fleet substituters in `modules/config/nix-settings.nix`
    apply;
  - Panix sets `XDG_CACHE_HOME=~/.cache/panix/…` for builds, so its eval
    cache is separate from your normal one.
- **Copying differs from deploy-rs:**
  - Panix doesn't pass `--substitute-on-destination`, so the whole closure
    goes from the control host;
  - deploy-rs lets the target fetch from caches;
  - for a VPS on a slow uplink, add `nix.copy_flags: [--substitute-on-destination]`
    (not tested).
- **Panix's Cachix cache isn't added.**
  - Trusting `mihakrumpestar.cachix.org-1:…` in `nix-settings.nix` would let
    whoever holds that signing key serve *any* store path to every fleet host,
    not just Panix.
  - Building from source takes seconds (Go, `vendorHash` pinned).
- **Maturity:**
  - v0.1.0 on 2026-03-10, v0.12.0 on 2026-10-24: 20 releases, about one every
    two weeks, all 0.x;
  - one maintainer (every commit), a thesis project, 91 stars, 4 forks;
  - 35 issues/PRs, 2 open (cosmetic);
  - unit coverage badge 82%;
  - `tests/e2e` is mostly a QEMU benchmark harness with 5 test functions,
    and nothing end-to-end covers rollback or lock-out;
  - HEAD has two commits after v0.12.0, including `bebad67` (the eval fix)
    and "overridable deploy commands".
- **Problems found here:**
  1. `panix eval` theme bug (worked around).
  2. A timeout is reported as "output not found" (worked around).
  3. Plain `--dry-run` previews the bootstrap path for installed hosts
     (recipe uses `--dry-run-with-inspect`).
  4. No per-host lock across installables (avoided by construction).
  5. Activation not under `systemd-run` (the link-loss split).
  6. No confirm-based rollback (section 1).
- **Licence:**
  - Panix is AGPL-3.0 (its `pkg/` is MIT);
  - running it as a tool is fine;
  - this repo builds it from the unmodified upstream source and doesn't
    vendor, patch, link or serve it to others;
  - if a fleet cache (e.g. `fleet.cachix.org`) ever pushes
    `packages.x86_64-linux.panix`, that distributes an AGPL binary; it's
    unmodified, so pointing at upstream's source satisfies it, but someone
    should know.

## 10. deploy-rs today vs Panix

| | deploy-rs (`nix run .#deploy-rs`, `just deploy`) | Panix (`just panix-*`) |
|---|---|---|
| Bootstrap | none (separate `just install` = nixos-anywhere, host-key checking off) | built in: installer or kexec → disko → nixos-install → reboot; installer path proven, kexec not |
| Build | local | local (or `build_mode: remote`) |
| Copy | `nix copy`, target substitutes from caches unless `fastConnection` | `nix copy --no-check-sigs`, everything from the control host |
| Activate | `activate-rs` on the target: `nix-env --set` + switch | `nix-env --set` + `switch-to-configuration switch` in the SSH session |
| Rollback safety | **magic rollback**: target reverts unless confirmed over a new connection within 30 s; auto-rollback on failure | auto-rollback **only on non-zero exit**; lock-outs go unnoticed; this PR's dead-man hook adds a target-side revert (lab-proven) |
| Mid-activation link loss | not tested | split host, no rollback |
| Secrets | none (sops-nix on host) | optional secrets phase (unused); sops-nix unchanged |
| darwin | not used (`just deploy-darwin`, password SSH) | `darwinConfigurations` preset (untested here) |
| home-manager | inside the system | inside the system; standalone homes possible |
| Visibility | log stream | TUI/console/JSON per phase; exact commands; dry-run with inspect |

## 11. Migration plan

| Stage | What | Go/no-go test |
|---|---|---|
| 1 (this PR) | Panix beside deploy-rs, manifest from `den.hosts`, recipes, VM proof | PR checks green (`checks.*.panix-manifest`, builds); the owner has read sections 1 and 2 |
| 2 | One real low-risk host by hand, **nomad**: a laptop that's physically reachable, not electric (Carter's, unattended) or THEBATTLESHIP. First fix the nomad/stowaway IP collision | `just panix-plan nomad` shows only the expected commands; `just panix-deploy nomad` with a trivial change shows the new generation live and the dead-man disarmed; then, **with the laptop in front of you**, deploy an sshd-on-another-port change and watch it revert within 300 s; `just panix-rollback nomad` restores the previous generation. **No-go** on any manual recovery |
| 3 | The rest: stowaway, THEBATTLESHIP; electric last; airlock only after a darwin test (a UTM VM or a spare Mac) | Two weeks of stage-2 use with zero manual recoveries; a Panix release containing `bebad67`, with `switch-to-configuration` under `systemd-run` (upstream, or via the new overridable commands); a reboot-in-window test on nomad |
| 4 | Remove deploy-rs (`modules/flake/deploy-rs.nix`, `just deploy`, the `deploy-rs-with-sops` app, the deploy checks) | Panix or the fleet wrapper has a confirm-over-new-connection rollback that survives a reboot (e.g. a persistent unit rather than `systemd-run`), proven on a real remote host; a month of Panix-only deploys; `just deploy` replaced; docs/deployment.md rewritten |

## 12. Not verified

- Any real activation by Panix (out of scope by design), and every darwin
  path.
- Kexec bootstrap from a non-NixOS image; `build_mode: remote`;
  `--substitute-on-destination` with Panix.
- The dead-man hook on real hardware, with a reboot inside its window, or with
  an activation longer than 300 s (THEBATTLESHIP's activation time wasn't
  measured).
- deploy-rs under link loss mid-activation; the dead-man hook under link loss.
- The lab ran nixpkgs 25.05, not the fleet's 26.11.
- sops-nix decrypting at first activation with a pre-placed host key: proven
  only up to "the installed host serves that key and its age recipient
  matches"; no real secret was used.
- Whether `fleet.cachix.org` would receive `packages.*.panix` from CI.
