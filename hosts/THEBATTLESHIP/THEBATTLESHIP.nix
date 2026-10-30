{
  inputs,
  fleet,
  den,
  __findFile,
  ...
}:
let
  danteChannels = import ./_data/dante-channels.nix;
in
{
  den.hosts.x86_64-linux = {
    THEBATTLESHIP = {
      description = "The Main System, ready for everyday battle (all users)";
      timeZone = "America/Los_Angeles";
      settings.cluster.k3s-agent = {
        dedicatedTo = [ "minecraft" ];
        nodeLabels = [ "fleet.fts/gpu=nvidia" ];
      };
      deployment.ip = "100.68.255.30";
      users.cody = {
        extraGroups = [
          "audio"
          "davfs2"
          "wireshark"
        ];
      };
      users.joshua = { };
      users.guest = { };
      users.bri = { };
      users.carter = { };
    };
  };

  den.aspects = {
    THEBATTLESHIP = {
      includes = [
        # k3s agent; membership (dedicated to minecraft, GPU label) is in
        # settings.cluster.k3s-agent on the host entry above.
        <fleet.cluster/k3s-agent>

        <fleet/fonts>
        <fleet/phoenix>
        <fleet/mactahoe>
        <fleet/stylix>
        <fleet.system/agent-user>
        # agent's `gh` / git push = fts-forge[bot]: workers open their own PRs.
        # cody's are his own, except inside Claude Code / Codex.
        (<fleet.coding.cli/gh-forge> {
          user = "agent";
          home = "/home/agent";
          humans = [ "cody" ];
          sopsFile = "${inputs.nix-secrets}/sops/hosts/THEBATTLESHIP.yaml";
        })
        # Claude Code + Codex go through the fleet proxy on starcommand (10G
        # fabric); per-user keys keep agent usage apart from Cody's.
        (<fleet.coding.cli/cliproxyapi-client> {
          baseUrl = "http://10.10.10.1:8317";
          sopsFile = "${inputs.nix-secrets}/sops/hosts/THEBATTLESHIP.yaml";
          users = {
            cody = "cody";
            agent = "agents";
          };
        })
        # Paperclip's native agents: Claude Code + Codex, self-updating.
        (<fleet.coding.cli/agent-clis> { users = [ "agent" ]; })
        <fleet.system/agent-bot-desktop> # Hermes bot screen for agent sessions over SSH
        den.aspects.THEBATTLESHIP-hermes-desktop # Hermes can drive cody's real desktop (forced-command key)
        (<fleet.system/cua-desktop> { user = "cody"; }) # cua-driver CLI + daemon for cody's session

        <fleet/desktop>
        <fleet/grub>

        <fleet/hardware>
        <fleet.hardware/nvidia>
        <fleet.networking/tailscale>
        <fleet.networking/rustdesk> # remote desktop over Tailscale (Sunshine is the unattended route)
        <fleet.hardware/zsa>

        <fleet/gaming>
        <fleet.apps/flatpaks> # Flatpak + Flathub (path to Flatpak bottles)
        <fleet.system/printing> # CUPS + mDNS network printer discovery
        <fleet.hardware/cuda> # CUDA toolkit (RTX present; nvidia already on)
        <fleet.apps/comfyui> # ComfyUI (CUDA) on :8188, models on the Development drive
        <fleet.apps/odysseus> # Odysseus launcher (server runs in Starcommand on this host, :7000)
        <fleet.hardware/iphone> # tether: iPhone messages / notifications / calls over Bluetooth
        # RT core isolation for the audio path — currently DISABLED (see
        # modules/audio/rt-isolation.nix): pinning pipewire to a
        # core before isolcpus is active starves it into a watchdog loop.
        # Re-enable deliberately, with a reboot, when chasing sub-1ms TX.
        # (fleet.audio._.rt-isolation { })
        (fleet.apps._.davinci-resolve { studio = true; })

        (<fleet.disk/btrfs> {
          device = "/dev/nvme2n1";
          withSwap = true;
          swapSize = "205";
          persistFolder = "/persist";
        })

        <fleet/kernel>

        # Music production host half (musnix plugin paths, millisecond,
        # easyeffects, fts-rigs); cody's per-user half is
        # <fleet.music._.production/producer> in his own aspect.
        <fleet.music/production>
        <fleet.audio/studio> # musnix RT tuning + RaySession
        <fleet.music._.production/mioctl> # iConnectivity mioXM MIDI router CLI

        # Dante: netaudio + inferno-control, plus this host's device/clock
        # below. Dante / Inferno: this host is "THEBATTLESHIP" on the 10G Dante
        # network, bound to the enp12s0 NIC. Statime does PTP clock sync,
        # Inferno exposes a 128-channel virtual Dante soundcard.
        (fleet.audio._.dante._.statime {
          interface = "enp12s0";
          # The Galaxy32's current Dante name (was the bare serial
          # "AA-4202524000109"; renamed to "Galaxy32"). The re-assert oneshot
          # looks the device up by this name, so it must match what the device
          # advertises or it fails silently. The preferred-leader flag is also
          # set directly on the device (persists in its NVRAM).
          preferredLeader = "Galaxy32";
          # MUST stay "debug" (or "trace"): at "warn" this statime fork loses a
          # startup race — it hits the announce-receipt timeout and self-promotes
          # to a PTPv1 master (unimplemented stub) before processing the leader's
          # first Sync, so the clock never locks and no Dante audio flows. The
          # extra per-packet logging delay lets the Sync win the race. Heisenbug.
          loglevel = "debug";
          # Belt-and-suspenders against the documented startup-race heisenbug
          # (see loglevel note above): ride through ~60 announce intervals before
          # ever declaring the master lost and self-promoting to the broken PTPv1
          # master stub. statime has no real clock and must NEVER be a grandmaster.
          # In normal operation it stays a clean follower anyway (BMCA only ever
          # recommends slave state) — this just removes the timeout edge case.
          announceReceiptTimeout = 60;
          # When the watchdog recovers a lost PTP lock, re-open the Inferno
          # PipeWire node against the now-valid clock (otherwise it stays frozen
          # in "init"). studio-routing-links is partOf wireplumber and re-wires.
          reinitOnRecovery = [ "wireplumber.service" ];
          # Without a clock the Inferno nodes wedge PipeWire's main loop and
          # stall the whole graph (TF included): gate them out when the clock
          # is lost for good, back in when it returns (studio-routing.nix).
          onLockLost = [ "/run/current-system/sw/bin/inferno-gate off || true" ];
          onLocked = [ "/run/current-system/sw/bin/inferno-gate on || true" ];
        })
        (fleet.audio._.dante._.inferno {
          bindIp = "10.10.10.10";
          deviceId = "00000A0A0A0A0001";
          channels = 64;
          # Dante TX+RX buffer for our inferno_aoip device. This value is ALSO
          # inferno's `max_lag_samples` (flows_tx.rs: "we set max_lag_samples to
          # tx latency because it doesn't make sense to send samples older than
          # that"): if the transmit thread is scheduled more than this late, the
          # flow is declared lagged and reset, producing continuous dropouts.
          # 0.5 ms (=24 samples @48k) was too tight — with RT isolation OFF and
          # the box under game/browser load, real scheduling jitter measured
          # ~29 samples (0.6 ms), so it tripped "tx lag of 29 samples" ~500x/30s
          # and NO audio transmitted. 2 ms (=96 samples) leaves comfortable
          # margin. Drop back toward 1 ms only after re-enabling RT core
          # isolation (see rt-isolation aspect) and confirming clean dante-soak.
          # The per-hop HARDWARE device RX latency (Galaxy32/TF/x16D, also 1 ms)
          # is set in Dante Controller — inferno-control can't change third-party
          # devices over ARC.
          # 2026-07-21: 0.5/0.5 ms — the rest of the Dante fleet runs
          # comfortably at 0.5 ms, and the fork (7a809db) split the
          # semantics: txLatencyNs = TX max_lag + ADVERTISED latency
          # (what receivers buffer for our flows); rxLatencyNs = playout
          # floor for incoming flows (network jitter only; clamped up by
          # the sender's advertised min). The old 0.5 ms pops predate
          # rt-pin + the source-led clock. Revert toward 2 ms if tx-lag
          # flow resets return.
          txLatencyNs = 500000;
          rxLatencyNs = 500000;
          # Labels live in ./_data/dante-channels.nix (rx ≡ what Reaper
          # records from; tx placeholders until the output layout is final).
          rxChannelNames = danteChannels.rx;
          txChannelNames = danteChannels.tx;
        })

        <fleet/audio/dante>

        <fleet.system/samba-client>

        # Codeberg Actions runner. Pre-created in the Codeberg UI (runner
        # "THEBATTLESHIP" on the codywright account) — UUID + secret live in
        # hosts/THEBATTLESHIP/secrets.yaml. Docker-only labels on purpose:
        # no `:host` label, so Codeberg CI never executes directly on the
        # workstation the way the trusted starcommand runner above does.
        (fleet.ci._.forgejo-runner {
          url = "https://codeberg.org/";
          name = "codeberg";
          uuidKey = "codeberg-runner-uuid";
          tokenKey = "codeberg-runner-token";
          tokenSopsFile = "${inputs.nix-secrets}/sops/hosts/THEBATTLESHIP.yaml";
          labels = [
            "docker:docker://node:lts"
            "ubuntu-latest:docker://catthehacker/ubuntu:act-latest"
          ];
        })

        # Second Codeberg runner, registered to the org rather than the
        # codywright account. Carries the `nix-host` HOST-mode label for
        # the FastTrackStudios image-publish workflows (Task images.yml
        # needs nix + docker on the host) — a DELIBERATE relaxation of the
        # docker-only policy above, decided 2026-06-12: only repos under
        # the account/org can dispatch to this runner and Cody is
        # effectively the sole committer, so the trust level matches the
        # starcommand runner. The codywright-account runner above keeps
        # the docker-only sandbox.
        (fleet.ci._.forgejo-runner {
          url = "https://codeberg.org/";
          name = "codeberg-org";
          uuidKey = "codeberg-org-runner-uuid";
          tokenKey = "codeberg-org-runner-token";
          tokenSopsFile = "${inputs.nix-secrets}/sops/hosts/THEBATTLESHIP.yaml";
          labels = [
            "docker:docker://node:lts"
            "ubuntu-latest:docker://catthehacker/ubuntu:act-latest"
            "nix-host:host"
          ];
        })

        # GitHub Actions runners: the nix-host pool plus one per project
        # (github-runners.nix).
        den.aspects.THEBATTLESHIP-github-runners

        <fleet.system/avahi>
        <fleet.system/virtualization>

        # 10G network tuning for starcommand link
        # Static 10.10.10.10/24 — outside starcommand dnsmasq DHCP range (.100-.200),
        # gives Hermes/agent a stable address to SSH to from starcommand.
        (fleet.networking._.network-10g {
          interface = "enp12s0";
          staticIp = "10.10.10.10/24";
        })
        # Host-local aspects split out of the former inline nixos block —
        # one file per concern in this directory.
        den.aspects.THEBATTLESHIP-audio-latency
        den.aspects.THEBATTLESHIP-niri-loft
        <fleet.desktop/loft/greeter> # Loft's login screen (cody runs Loft; the others keep Noctalia)
        den.aspects.THEBATTLESHIP-storage
        den.aspects.THEBATTLESHIP-starcommand-net
        den.aspects.THEBATTLESHIP-sops
        den.aspects.THEBATTLESHIP-studio-routing
        den.aspects.THEBATTLESHIP-net-analysis
        den.aspects.THEBATTLESHIP-dante-net
      ];

      nixos =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        {
          boot.loader.grub.configurationLimit = 3;
          services.dbus.implementation = "dbus";

          # Minecraft runs as a k3s hostPort workload on this node.
          networking.firewall.allowedTCPPorts = [ 25565 ];

          # automatic + --delete-older-than 7d come from <fleet/nix-settings>.
          nix.gc.dates = "weekly";

          programs.nh.enable = true;

          security.sudo.extraRules = [
            {
              users = [ "cody" ];
              commands = [
                {
                  command = "ALL";
                  options = [ "NOPASSWD" ];
                }
              ];
            }
          ];
        };
    };
  };
}
