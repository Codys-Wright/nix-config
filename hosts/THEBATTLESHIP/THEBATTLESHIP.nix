{
  inputs,
  fleet,
  den,
  __findFile,
  ...
}:
{
  den.hosts.x86_64-linux = {
    THEBATTLESHIP = {
      description = "The Main System, ready for everyday battle (all users)";
      timeZone = "America/Los_Angeles";
      # t3code.service, served on the tailnet by Tailscale Serve (:8443).
      t3 = {
        url = "https://thebattleship.tail666c4b.ts.net:8443";
        sshUser = "cody";
      };
      settings.cluster.k3s-agent = {
        dedicatedTo = [ "minecraft" ];
        nodeLabels = [ "fleet.fts/gpu=nvidia" ];
      };
      # Hermes on starcommand reaches the model server over the 10G link.
      settings.ai.llama-server.interfaces = [
        "tailscale0"
        "enp12s0"
      ];
      # Boots (autologin) into KDE Plasma with Loft's shell; "Plasma" and
      # "niri" stay at the login screen.
      settings.desktop.session = "loft";
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
        # agent's queued build gates (gate-submit) run in a user unit
        # and wake their Paperclip issue when done (STA-402).
        (<fleet.coding.cli/gate-queue> { user = "agent"; })
        # No cliproxyapi-client here: Claude Code signs in directly
        # (claude.ai login) so Code Mode works — it refuses third-party base URLs.
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
        <fleet.ai/llama-server> # local LLMs: llama.cpp router on :8012 (`llm` CLI)
        <fleet.ai/laya> # Laya decisions: Jev /v1/systemone on 127.0.0.1:11435, GPU when VRAM allows (STA-630)
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
        # easyeffects); cody's per-user half is
        # <fleet.music._.production/producer> in his own aspect.
        <fleet.music/production>
        <fleet.audio/studio> # musnix RT tuning + RaySession
        <fleet.music._.production/mioctl> # iConnectivity mioXM MIDI router CLI

        # No Dante here any more: a Raspberry Pi is the Dante interface and
        # joins as a USB audio device. The fleet.audio.dante aspects stay for it.

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
        den.aspects.THEBATTLESHIP-ci-slice # all runners share one CPU cap (ci.slice)

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
        den.aspects.THEBATTLESHIP-loft-cache # push Loft + patched KWin to loft.cachix.org after each switch
        den.aspects.THEBATTLESHIP-storage
        den.aspects.THEBATTLESHIP-kache # one kache store for cody and the FastTrackStudios runners
        den.aspects.THEBATTLESHIP-kache-nix-sandbox # that store inside the nix sandbox, for builds that opt in (studio's release image)
        den.aspects.THEBATTLESHIP-remote-reboot # autologin at boot + safe-reboot (waits for CI jobs and nix builds)
        den.aspects.THEBATTLESHIP-btrfs-maintenance
        den.aspects.THEBATTLESHIP-target-sweep # hourly bounded cargo sweep of task/target
        den.aspects.THEBATTLESHIP-starcommand-net
        den.aspects.THEBATTLESHIP-sops
        den.aspects.THEBATTLESHIP-studio-routing
        den.aspects.THEBATTLESHIP-net-analysis
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
