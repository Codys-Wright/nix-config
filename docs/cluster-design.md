# Fleet Cluster Design

Status: Phase 1 in progress (2026-06-12)

## Goal

One k3s cluster across the fleet where:

- **starcommand** is the always-on anchor: control plane + the NAS holding all
  real data. Services run *in the cluster*, not as selfhostblocks NixOS
  services — selfhostblocks retires service-by-service as each one migrates.
- **Every other machine is an opportunistic agent** (THEBATTLESHIP, airlock,
  dave, laptops): joins when idle/available, drains and leaves when its owner
  wants it back. Joining is `cluster-on`, leaving is `cluster-off`.
- **Compute survives starcommand going down** (pods reschedule onto agents in
  ~1–3 min); *data* does not until a replica server exists — that is an
  accepted, designed-for limitation (see "Storage evolution").
- **VPS agents can be added at any time** (not enabled yet) via k3s's
  tailscale integration — the agent aspect carries a `viaTailscale` switch.

## Topology

```
starcommand (always-on)            other fleet machines           future
┌─────────────────────────┐   ┌──────────────────────────┐   ┌────────────┐
│ k3s server (embedded    │   │ k3s agents, opt-in:      │   │ VPS agent  │
│ etcd, clusterInit) ◄────┼───┤  taint fleet.fts/        │   │ tailscale, │
│ NAS / NFS exports       │   │  opportunistic:NoSchedule│   │ offsite    │
│ csi-driver-nfs backend  │   │  cluster-on/off + drain  │   │ taint      │
│ restic → offsite        │   │  THEBATTLESHIP: +GPU     │   └────────────┘
└─────────────────────────┘   └──────────────────────────┘
```

### Decisions and why

| Decision | Rationale |
|---|---|
| **Embedded etcd from day one** (`clusterInit`), even single-server | Lets a second/third server join later for HA without datastore migration. etcd on one node costs little. |
| Control plane stays home (never on a VPS) | etcd over WAN is explicitly unsupported by k3s and discouraged by etcd tuning docs. |
| Agents are **tainted** `fleet.fts/opportunistic=true:NoSchedule` | Only workloads that explicitly tolerate interruption land on part-time machines. Always-safe default. |
| Join/leave = `systemctl start/stop k3s` via `cluster-on`/`cluster-off` | Cordon/drain state is durable API state; k3s agents auto-re-register. A companion unit uncordons on start and drains on stop, so membership is one systemd action. |
| Drain runs *before* agent stop (`BindsTo` companion unit) | Verified community pattern (oranki.net / psdn.io). Dirty exits are still safe: short `tolerationSeconds` on opportunistic workloads bounds rescheduling to ~1–5 min. |
| `k3s-killall` only on explicit `cluster-off --hard` | Stopping k3s.service leaves containers running (by design); killall reclaims CPU/GPU instantly when the owner needs the machine. |
| **csi-driver-nfs** against starcommand's NAS | All nodes already mount it; replicated storage (Longhorn/Ceph) is the known-bad fit for come-and-go nodes. Swap path documented below. |
| **nixidy** renders all manifests (GitOps) | `services.k3s.manifests` never prunes; nixidy is the actively-maintained Nix→k8s render layer and matches the "everything is nix" rule. |
| Apps via helm charts/operators rendered by nixidy | selfhostblocks is NixOS-only by design; the cluster needs first-class k8s deployments. |

## Membership mechanics (agent aspect)

- `services.k3s` role=agent, `wantedBy = []` — **never auto-joins at boot**.
- `cluster-on`  → `systemctl start k3s` → companion unit uncordons the node.
- `cluster-off` → companion's `ExecStop` drains (`--ignore-daemonsets
  --delete-emptydir-data --timeout=120s`) → k3s stops. `--hard` additionally
  runs `k3s-killall.sh`.
- Optional triggers to layer on later: gamemode start/stop hooks on
  THEBATTLESHIP (drain when a game launches — better signal than idle), niri
  `ext-idle-notify` via swayidle/hypridle (input-idle misdetects audio
  playback; gate on CPU/PipeWire activity if ever enabled).
- Drain credentials: a dedicated ServiceAccount kubeconfig (nodes get/patch,
  pods list, pods/eviction create) distributed via nix-secrets shared.yaml.

## Storage evolution (the "add a replica server" socket)

Today: StorageClass `nas-nfs` (csi-driver-nfs → starcommand). All stateful
workloads reference **StorageClass names by intent**, never a node:

- `nas-nfs` — bulk data, media, documents
- `db-local` — local-path on starcommand for SQLite/postgres data dirs
  (SQLite-on-NFS corruption is a real trap)

When a second storage server arrives, options in order of preference:
1. ZFS replication of the NAS dataset + democratic-csi (`zfs-generic-nfs`),
   failover by repointing the StorageClass.
2. Longhorn **pinned to always-on nodes only** (its failure mode is flaky
   replicas, so never on opportunistic agents).
3. CloudNativePG for databases (streaming replication is the proper HA story
   for postgres-backed apps — first candidate when zero-downtime data matters).

Backups stay at the NixOS level on starcommand: restic (filesystem snapshot →
offsite/VPS) + `k3s etcd-snapshot` into the same restic job. Velero rejected
(not crash-consistent over NFS).

## VPS readiness (designed, not enabled)

- Agent aspect takes `viaTailscale = true` → adds `--vpn-auth
  name=tailscale,joinKey=…` + `--node-external-ip`; server already advertises
  a tailscale `--tls-san`.
- VPS nodes get taint `fleet.fts/offsite=true:NoSchedule`; they must never
  mount the home NAS (workloads there are stateless or VPS-local).
- Adding one = `nixos-anywhere` install from this flake + include the agent
  aspect with `viaTailscale = true` + `just add-host` in nix-secrets.

## Service migration roadmap (selfhostblocks → nixidy)

Order: easiest/stateless first, each one establishes the pattern for the next.

1. open-webui, pinchflat, audiobookshelf-style apps (single PVC, no DB)
2. forgejo (postgres via CloudNativePG, repos PVC on nas-nfs) — note forgejo
   at git.starcommand.live is now a mirror of Codeberg; low blast radius
3. immich / jellyfin (media on nas-nfs, transcode as opportunistic jobs)
4. ollama + AI stack (GPU RuntimeClass on THEBATTLESHIP, opportunistic taint
   toleration, LiteLLM-style router falls back to starcommand CPU)
5. nextcloud (helm chart; postgres on CloudNativePG; files on nas-nfs) — last,
   it is the heaviest and most entangled (LDAP/Authelia/talk/whiteboard)
6. ingress: cloudflared as an in-cluster Deployment (replicated) replaces the
   host-level tunnel, so ingress survives starcommand restarts
7. mailserver: likely **never** k8s (deliverability + stateful daemons); keep
   as NixOS service or hosted.

Auth (LLDAP/Authelia) migrates alongside the first app that needs it.

## Phase plan

- **Phase 0** (free win, independent): nix remote builders starcommand ↔
  THEBATTLESHIP (`ssh-ng`, `big-parallel`).
- **Phase 1** (this change): k3s server on starcommand (etcd), opportunistic
  agent aspect in fleet, THEBATTLESHIP wired with cluster-on/off + drain,
  token in nix-secrets shared.yaml, cluster verified.
- **Phase 2**: csi-driver-nfs, nixidy scaffold + Argo CD, first app migrated.
- **Phase 3**: GPU RuntimeClass on THEBATTLESHIP (nixpkgs NVIDIA.md recipe,
  CDI plugin — watch the CDI-vs-driver boot race with the open module),
  gamemode trigger, more agents (airlock, dave).
- **Phase 4**: service migration down the roadmap; cloudflared in-cluster.
- **Phase 5** (when needed): second storage server / VPS agents / third etcd
  member for true starcommand-off operation.

## References

Key sources: nixpkgs k3s docs tree (README/USAGE/NVIDIA.md), rorosen/k3s-nix,
oranki.net graceful-k3s-shutdown, psdn.io kubelet-graceful-shutdown, k3s
distributed-multicloud (tailscale + etcd-over-WAN prohibition), arnarg/nixidy,
csi-driver-nfs, tyzbit's Longhorn experience report, k3s backup-restore docs.
