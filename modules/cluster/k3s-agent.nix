# k3s agent — fleet machines join the cluster. Two modes:
#
#   Opportunistic (default): membership is OPT-IN, never starts at boot.
#   `cluster-on` joins (+ uncordons), `cluster-off` drains and leaves,
#   `cluster-off --hard` also k3s-killalls to reclaim CPU/GPU instantly. The
#   node carries taint fleet.fts/opportunistic=true:NoSchedule, so only
#   workloads that tolerate interruption (a service's placement.opportunistic)
#   ever burst here. E.g. THEBATTLESHIP.
#
#   Dedicated (`dedicatedTo = [ "svc" ]`): a permanent home for specific
#   services — per-service taint fleet.fts/dedicated=<svc>:NoSchedule + label
#   fleet.fts/svc.<svc>=true, and JOINS AT BOOT. Pairs with a service's
#   placement.node = "<svc>". E.g. a Raspberry Pi running only pihole.
#
# Design doc: docs/cluster-design.md; see also docs/add-a-cluster-node.md.
{
  fleet,
  inputs,
  lib,
  ...
}:
{
  fleet.cluster._.k3s-agent.description =
    "Opt-in k3s agent joining the starcommand cluster (cluster-on/off toggles)";
  fleet.cluster._.k3s-agent.__functor =
    _self:
    {
      # k3s API endpoint; default = starcommand over the fleet VPN
      serverAddr ? "https://10.10.10.1:6443",
      # extra node taints; opportunistic taint is always applied
      extraTaints ? [ ],
      # extra node labels, e.g. [ "fleet.fts/gpu=nvidia" ]
      nodeLabels ? [ ],
      # Dedicate this node to one or more services. Instead of the opportunistic
      # taint, apply `fleet.fts/dedicated=<svc>:NoSchedule` + label
      # `fleet.fts/svc.<svc>=true` per service, and JOIN AT BOOT — a dedicated
      # node is a permanent home for its service, not an on-demand burst node.
      # Matches a service's `placement.node`. E.g. a pihole Raspberry Pi:
      #   (<fleet.cluster/k3s-agent> { dedicatedTo = [ "pihole" ]; })
      dedicatedTo ? [ ],
      # future: VPS/offsite agents join over tailscale
      viaTailscale ? false,
      ...
    }:
    {
      nixos =
        { config, pkgs, ... }:
        let
          nodeName = lib.toLower config.networking.hostName;
          # Dedicated nodes carry per-service taints/labels and join at boot;
          # the default (non-dedicated) node is an opt-in opportunistic burst node.
          isDedicated = dedicatedTo != [ ];
          nodeTaints =
            if isDedicated then
              map (s: "fleet.fts/dedicated=${s}:NoSchedule") dedicatedTo
            else
              [ "fleet.fts/opportunistic=true:NoSchedule" ];
          svcLabels = map (s: "fleet.fts/svc.${s}=true") dedicatedTo;
          drainCmd = "KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl drain ${nodeName} --ignore-daemonsets --delete-emptydir-data --timeout=120s";
          # v1: drain/uncordon run on the server over SSH (root@server has
          # cluster-admin kubectl). Phase 3 replaces this with a local
          # drain-scoped ServiceAccount kubeconfig from nix-secrets.
          serverSsh = "ssh -o ConnectTimeout=10 -o BatchMode=yes root@10.10.10.1";

          cluster-on = pkgs.writeShellApplication {
            name = "cluster-on";
            runtimeInputs = [ pkgs.openssh ];
            text = ''
              sudo systemctl start k3s.service
              echo "k3s agent started; uncordoning ${nodeName}..."
              ${serverSsh} "KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl uncordon ${nodeName}" || \
                echo "uncordon failed (node may not be registered yet — run cluster-on again in ~30s)"
            '';
          };

          cluster-off = pkgs.writeShellApplication {
            name = "cluster-off";
            runtimeInputs = [ pkgs.openssh ];
            text = ''
              hard=0
              [ "''${1:-}" = "--hard" ] && hard=1
              echo "draining ${nodeName} (waits for workloads to evict)..."
              ${serverSsh} "${drainCmd}" || echo "drain failed/timed out — continuing"
              sudo systemctl stop k3s.service
              if [ "$hard" = 1 ]; then
                echo "killing remaining containers (k3s-killall)..."
                sudo k3s-killall.sh || true
              else
                echo "note: running containers keep running until 'cluster-off --hard'"
              fi
            '';
          };
        in
        {
          imports = [ inputs.sops-nix.nixosModules.sops ];

          services.k3s = {
            enable = true;
            # Pin to the server minor: kubelet must never be NEWER than the
            # API server (version-skew policy). starcommand (nixpkgs 25.11)
            # runs k3s 1.33; fleet hosts on newer nixpkgs would drift ahead.
            package = pkgs.k3s_1_33;
            role = "agent";
            inherit serverAddr;
            tokenFile = config.sops.secrets."k3s/token".path;
            extraFlags = [
              "--node-name=${nodeName}"
            ]
            ++ map (t: "--node-taint=${t}") (nodeTaints ++ extraTaints)
            ++ map (l: "--node-label=${l}") (nodeLabels ++ svcLabels)
            ++ lib.optionals viaTailscale [
              # requires tailscale up + a join key; see docs/cluster-design.md
              "--vpn-auth-file=/run/secrets/k3s/tailscale-auth"
            ];
          };

          # Opportunistic nodes are opt-in (cluster-on); dedicated nodes are the
          # permanent home for their service, so they join at boot.
          systemd.services.k3s.wantedBy = lib.mkForce (lib.optional isDedicated "multi-user.target");

          sops.secrets."k3s/token" = {
            sopsFile = "${inputs.nix-secrets}/sops/shared.yaml";
          };

          networking.firewall = {
            allowedTCPPorts = [ 10250 ]; # kubelet (logs/exec from control plane)
            allowedUDPPorts = [ 8472 ]; # flannel VXLAN
          };

          environment.systemPackages = [
            cluster-on
            cluster-off
            pkgs.kubectl
          ];
        };
    };
}
