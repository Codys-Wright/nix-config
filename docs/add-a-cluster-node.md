# Add any computer to the fleet k3s cluster

Turning a NixOS machine into an opt-in cluster node. The control plane is
**starcommand** (`https://10.10.10.1:6443`, the 10G fleet LAN). Membership is
**opt-in** — the k3s agent never starts at boot; you run `cluster-on` to join
and `cluster-off` to leave. Nodes carry the taint
`fleet.fts/opportunistic=true:NoSchedule`, so only workloads that tolerate
interruption ever land on them.

The join mechanism already exists (`<fleet.cluster/k3s-agent>`); THEBATTLESHIP
uses it. This is the repeatable recipe for a NEW machine.

> Reachability: the agent's default `serverAddr` is `https://10.10.10.1:6443`,
> so the machine must be able to reach starcommand on the 10.10.10.0/24 fleet
> LAN. Off-LAN/internet nodes would need a mesh VPN (Tailscale) — out of scope
> here; this covers LAN-reachable machines.

## One-time per machine

### 1. Enroll the host in sops (so it can read the k3s join token)

The join token lives in `sops/shared.yaml` (encrypted to every host). A new
machine needs its **age key** (derived from its SSH host key) added as a
recipient, then the secrets re-encrypted.

```bash
# In ~/nix-secrets:
# a) get the new host's age key (needs SSH reachable, or read its
#    /etc/ssh/ssh_host_ed25519_key.pub and pipe through ssh-to-age)
nix shell nixpkgs#ssh-to-age -c sh -c \
  'ssh <host> cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age'

# b) add it to .sops.yaml: a new `- &<host> age1...` under `hosts:`,
#    and add `*<host>` to the `key_groups.age` list of the
#    `sops/shared\.yaml$` creation rule (so the token re-encrypts to it).

# c) re-encrypt every sops file to the updated recipients, then repin:
just rekey-secrets      # (or: sops updatekeys sops/shared.yaml) + repin input
```

A fresh box that hasn't generated its SSH host key yet: deploy it once
(step 3) so the key exists, grab the key, then do this step and redeploy.

### 2. Declare the host with the agent aspect

Minimal host file — the agent is a single include. Example
`hosts/<NAME>/<NAME>.nix`:

```nix
{ inputs, fleet, __findFile, ... }:
{
  den.hosts.x86_64-linux.<NAME> = {
    users.cody = { };
    aspect = "<NAME>";
  };

  den.aspects.<NAME> = {
    includes = [
      # ── the cluster node, opt-in ──
      (<fleet.cluster/k3s-agent> {
        # nodeLabels = [ "fleet.fts/gpu=nvidia" ]; # optional, e.g. for ML pods
        # extraTaints = [ ];                       # optional
      })
      <fleet.system/agent-user>   # the unprivileged ops user the agent uses

      # ── the usual host plumbing (real machine) ──
      (fleet.grub { uefi = true; })
      (<fleet.system/disk> { type = "..."; device = "/dev/..."; })
      # + facter.json from `nixos-facter`, timezone, etc.
    ];
  };
}
```

```bash
git add hosts/<NAME>/<NAME>.nix      # import-tree only sees tracked files
```

### 3. Deploy

```bash
just deploy <NAME>      # deploy-rs (remote, rollback) — or `just switch` on-box
```

## Joining / leaving (repeatable)

On the node:

```bash
cluster-on              # start the agent + uncordon (joins the cluster)
cluster-off             # drain + stop the agent (workloads keep running)
cluster-off --hard      # also k3s-killall to reclaim CPU/GPU instantly
```

`cluster-on` runs the agent and asks the server to uncordon the node. If it
prints "uncordon failed (node may not be registered yet)", wait ~30s and run
`cluster-on` again.

## Verify

```bash
# on starcommand (or anywhere with the cluster kubeconfig):
kubectl get nodes -o wide        # the new node should be Ready
kubectl get node <name> -o jsonpath='{.spec.taints}'   # opportunistic taint present
```

## Notes

- **k3s version pin:** the agent pins `pkgs.k3s_1_33` to match the server minor
  (kubelet must never be newer than the API server). If starcommand's k3s minor
  moves, bump the agent pin to match.
- **Scheduling:** nothing schedules onto a new node unless the workload
  tolerates `fleet.fts/opportunistic=true:NoSchedule`. Add a toleration (and
  optionally a `nodeLabels` selector) to pods you want to burst onto fleet
  machines.
- **GPU nodes:** label with `fleet.fts/gpu=nvidia` and the node can host the
  GPU workloads (immich-ml, etc.) when on.
