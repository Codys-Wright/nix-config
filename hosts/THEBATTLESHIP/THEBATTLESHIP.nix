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
      provides.to-users.includes = [ <fleet.desktop/home> ];

      includes = [
        # Opportunistic k3s agent: join with cluster-on, leave with cluster-off.
        (<fleet.cluster/k3s-agent> {
          nodeLabels = [ "fleet.fts/gpu=nvidia" ];
        })

        <fleet/unfree>
        <fleet/fonts>
        <fleet/phoenix>
        <fleet/mactahoe>
        <fleet/stylix>
        <fleet.system/agent-user>

        (fleet.desktop { default = "niri"; })
        (fleet.grub { uefi = true; })

        (fleet.hardware {
          nvidia = true;
          tailscale = true;
          zsa = true;
        })

        <fleet/gaming>
        <fleet/apps>
        <fleet.apps/flatpaks> # Flatpak + Flathub (path to Flatpak bottles)
        <fleet.system/printing> # CUPS + mDNS network printer discovery
        <fleet.hardware/cuda> # CUDA toolkit (RTX present; nvidia already on)
        <fleet/raysession> # RaySession audio session manager
        # RT core isolation for the audio path — currently DISABLED (see
        # modules/hardware/audio/rt-isolation.nix): pinning pipewire to a
        # core before isolcpus is active starves it into a watchdog loop.
        # Re-enable deliberately, with a reboot, when chasing sub-1ms TX.
        # (fleet.hardware._.audio._.rt-isolation { })
        (fleet.apps._.davinci-resolve { studio = true; })
        # controller-split bundles polkit + sudoers + InputPlumber config +
        # the launch-as / steam-as equivalents. Replaces the three modules
        # that used to live here (launch-as, inputplumber, coop-launcher).
        <fleet.gaming/controller-split>

        (<fleet.system/disk> {
          type = "btrfs-impermanence";
          device = "/dev/nvme2n1";
          withSwap = true;
          swapSize = "205";
          persistFolder = "/persist";
        })

        <fleet/kernel>

        # Music production base (Reaper, plugins, netaudio, environment).
        <fleet.music/production>

        # Dante / Inferno: this host is "THEBATTLESHIP" on the 10G Dante
        # network, bound to the enp12s0 NIC. Statime does PTP clock sync,
        # Inferno exposes a 128-channel virtual Dante soundcard.
        (fleet.music._.production._.statime {
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
        })
        (fleet.music._.production._.inferno {
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
          # RX channel names ≡ THEBATTLESHIP's "inputs" — these are
          # what Reaper records from. Sourced from the Reaper chanmap
          # at ~/.fasttrackstudio/Reaper/ChanMaps/THEBATTLESHIP.ReaperChanMap;
          # regenerate with `~/.flake/scripts/set_dante_channel_names.py`
          # if/when the chanmap changes.
          rxChannelNames = {
            "1" = "1 - Kick In";
            "2" = "2 - Kick Out";
            "3" = "3 - Snare Top";
            "4" = "4 - Snare Bottom";
            "5" = "5 - Tom 1";
            "6" = "6 - Tom 2";
            "7" = "7 - Tom 3";
            "8" = "8 - Tom 4";
            "9" = "9 - Hi-Hat";
            "10" = "10 - Ride";
            "11" = "11 - OH L";
            "12" = "12 - OH R";
            "13" = "13 - Room L";
            "14" = "14 - Room R";
            "15" = "15 - E-Kit L";
            "16" = "16 - E-Kit R";
            "17" = "17 - Drum Pad L";
            "18" = "18 - Drum Pad R";
            "19" = "19 - Bass DI";
            "20" = "20 - Bass Amp";
            "21" = "21 - Guitar 1 L";
            "22" = "22 - Guitar 1 R";
            "23" = "23 - Guitar 2 L";
            "24" = "24 - Guitar 2 R";
            "25" = "25 - Guitar 1 DI";
            "26" = "26 - Guitar 2 DI";
            "27" = "27 - Acoustic 1";
            "28" = "28 - Acoustic 2";
            "29" = "29 - Keys 1 L";
            "30" = "30 - Keys 1 R";
            "31" = "31 - Keys 2 L";
            "32" = "32 - Keys 2 R";
            "33" = "33 - Vox 1 L";
            "34" = "34 - Vox 1 R";
            "35" = "35 - Vox 2";
            "36" = "36 - Vox 3";
            "37" = "37 - Vox 4";
            "38" = "38 - Vox 5 [Drums]";
            "39" = "39 - Vox 6 [Bass]";
            "40" = "40 - Vox 7 [Guitar]";
            "41" = "41 - Vox 8 [Keys]";
            "42" = "42 - Vox 9 [Engineer]";
            "43" = "43 - Vox 10 [Producer]";
            "44" = "44 - Kick [DSP]";
            "45" = "45 - Snare [DSP]";
            "46" = "46 - Vox 1 L [DSP]";
            "47" = "47 - Vox 1 R [DSP]";
            "48" = "48 - Vox 2 [DSP]";
            "49" = "49 - Vox 3 [DSP]";
            "50" = "50 - Vox 4 [DSP]";
            "51" = "51 - Vox 9 [Engineer] [DSP]";
            "52" = "52 - Click";
            "53" = "53 - Headphone Mix L";
            "54" = "54 - Headphone Mix R";
            "55" = "55 - Processed HP Mix L";
            "56" = "56 - Processed HP Mix R";
            "57" = "57 - System L";
            "58" = "58 - System R";
            "59" = "59 - Voice Chat L";
            "60" = "60 - Voice Chat R";
            "61" = "61 - DAW L";
            "62" = "62 - DAW R";
            "63" = "63 - Broadcast L";
            "64" = "64 - Broadcast R";
          };
          # TX channel names — placeholder labels until we lock in the
          # broadcast/output layout. `N - OUTN` makes every slot unique
          # so Dante Controller and other receivers can target a specific
          # channel without ambiguity, and identifies the slot number
          # inline. Replace with meaningful labels alongside the
          # rxChannelNames map when the routing is finalised.
          txChannelNames = {
            "1" = "1 - OUT1";
            "2" = "2 - OUT2";
            "3" = "3 - OUT3";
            "4" = "4 - OUT4";
            "5" = "5 - OUT5";
            "6" = "6 - OUT6";
            "7" = "7 - OUT7";
            "8" = "8 - OUT8";
            "9" = "9 - OUT9";
            "10" = "10 - OUT10";
            "11" = "11 - OUT11";
            "12" = "12 - OUT12";
            "13" = "13 - OUT13";
            "14" = "14 - OUT14";
            "15" = "15 - OUT15";
            "16" = "16 - OUT16";
            "17" = "17 - OUT17";
            "18" = "18 - OUT18";
            "19" = "19 - OUT19";
            "20" = "20 - OUT20";
            "21" = "21 - OUT21";
            "22" = "22 - OUT22";
            "23" = "23 - OUT23";
            "24" = "24 - OUT24";
            "25" = "25 - OUT25";
            "26" = "26 - OUT26";
            "27" = "27 - OUT27";
            "28" = "28 - OUT28";
            "29" = "29 - OUT29";
            "30" = "30 - OUT30";
            "31" = "31 - OUT31";
            "32" = "32 - OUT32";
            "33" = "33 - OUT33";
            "34" = "34 - OUT34";
            "35" = "35 - OUT35";
            "36" = "36 - OUT36";
            "37" = "37 - OUT37";
            "38" = "38 - OUT38";
            "39" = "39 - OUT39";
            "40" = "40 - OUT40";
            "41" = "41 - OUT41";
            "42" = "42 - OUT42";
            "43" = "43 - OUT43";
            "44" = "44 - OUT44";
            "45" = "45 - OUT45";
            "46" = "46 - OUT46";
            "47" = "47 - OUT47";
            "48" = "48 - OUT48";
            "49" = "49 - OUT49";
            "50" = "50 - OUT50";
            "51" = "51 - OUT51";
            "52" = "52 - OUT52";
            "53" = "53 - Headphone Mix L";
            "54" = "54 - Headphone Mix R";
            "55" = "55 - Processed HP Mix L";
            "56" = "56 - Processed HP Mix R";
            "57" = "57 - System L";
            "58" = "58 - System R";
            "59" = "59 - Voice Chat L";
            "60" = "60 - Voice Chat R";
            "61" = "61 - DAW L";
            "62" = "62 - DAW R";
            "63" = "63 - Broadcast L";
            "64" = "64 - Broadcast R";
          };
        })

        # System-wide inferno-control CLI — Rust port of
        # network-audio-controller. Pairs with the inferno_aoip
        # soundcard above for ad-hoc Dante inspection / control without
        # leaving the host.
        <fleet.music/production/inferno-control>

        (fleet.selfhost._.samba-client { })

        # Codeberg Actions runner. Pre-created in the Codeberg UI (runner
        # "THEBATTLESHIP" on the codywright account) — UUID + secret live in
        # hosts/THEBATTLESHIP/secrets.yaml. Docker-only labels on purpose:
        # no `:host` label, so Codeberg CI never executes directly on the
        # workstation the way the trusted starcommand runner above does.
        (fleet.selfhost._.forgejo-runner {
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
        (fleet.selfhost._.forgejo-runner {
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

        # GitHub-native self-hosted runner (org-level, label `nix-host`).
        # Replaces the Codeberg-mirror trigger now that GitHub is canonical:
        # lets .github/workflows/deploy.yml build + push images on the LAN.
        # Defaults cover url/name/labels/tokenKey; only the sops file differs.
        (fleet.selfhost._.github-runner {
          tokenSopsFile = "${inputs.nix-secrets}/sops/hosts/THEBATTLESHIP.yaml";
        })

        <fleet.system/avahi>
        <fleet.system/virtualization>
        (fleet.deploy { ip = "100.68.255.30"; })

        # 10G network tuning for starcommand link
        # Static 10.10.10.10/24 — outside starcommand dnsmasq DHCP range (.100-.200),
        # gives Hermes/agent a stable address to SSH to from starcommand.
        (fleet.system._.network-10g {
          interface = "enp12s0";
          staticIp = "10.10.10.10/24";
        })
        # Host-local aspects split out of the former inline nixos block —
        # one file per concern in this directory.
        den.aspects.THEBATTLESHIP-audio-latency
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
          time.timeZone = "America/Los_Angeles";
          boot.loader.grub.configurationLimit = 3;
          services.dbus.implementation = "dbus";

          nix.gc = {
            automatic = true;
            dates = "weekly";
            options = "--delete-older-than 7d";
          };

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
