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
          channels = 128;
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
          latencyNs = 2000000;
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
            "15" = "15 - Room Far L";
            "16" = "16 - Room Far R";
            "17" = "17 - Electronic Kit L";
            "18" = "18 - Electronic Kit R";
            "19" = "19 - Drum Pad L";
            "20" = "20 - Drum Pad R";
            "21" = "21 - Bass DI";
            "22" = "22 - Bass Amp";
            "23" = "23 - Bass Synth L";
            "24" = "24 - Bass Synth R";
            "25" = "25 - Guitar 1 L";
            "26" = "26 - Guitar 1 R";
            "27" = "27 - Guitar 2 L";
            "28" = "28 - Guitar 2 R";
            "29" = "29 - Guitar 3 L";
            "30" = "30 - Guitar 3 R";
            "31" = "31 - Guitar 1 DI";
            "32" = "32 - Guitar 2 DI";
            "33" = "33 - Guitar 3 DI";
            "34" = "34 - Keys 1 L";
            "35" = "35 - Keys 1 R";
            "36" = "36 - Keys 2 L";
            "37" = "37 - Keys 2 R";
            "38" = "38 - Keys 3 L";
            "39" = "39 - Keys 3 R";
            "40" = "40 - Lead Mic L";
            "41" = "41 - Lead Mic R";
            "42" = "42 - Engineer Vocal";
            "43" = "43 - Drummer Mic";
            "44" = "44 - Bass Talkback";
            "45" = "45 - Guitar 1 Talkback";
            "46" = "46 - Guitar 2 Talkback";
            "47" = "47 - Keys 1 Talkback";
            "48" = "48 - Keys 2 Talkback";
            "49" = "49 - Wireless Mic 1";
            "50" = "50 - Wireless Mic 2";
            "51" = "51 - Producer Talkback";
            "52" = "52 - Generic Talkback";
            "53" = "53 - Spare 1";
            "54" = "54 - Spare 2";
            "55" = "55 - Spare 3";
            "56" = "56 - Spare 4";
            "57" = "57 - Spare 5";
            "58" = "58 - Spare 6";
            "59" = "59 - Spare 7";
            "60" = "60 - Spare 8";
            "61" = "61 - Spare 9";
            "62" = "62 - Spare 10";
            "63" = "63 - Spare 11";
            "64" = "64 - Spare 12";
            "65" = "65 - Kick In [DSP]";
            "66" = "66 - Kick Out [DSP]";
            "67" = "67 - Snare Top [DSP]";
            "68" = "68 - Snare Bottom [DSP]";
            "69" = "69 - Tom 1 [DSP]";
            "70" = "70 - Tom 2 [DSP]";
            "71" = "71 - Tom 3 [DSP]";
            "72" = "72 - Tom 4 [DSP]";
            "73" = "73 - Hi-Hat [DSP]";
            "74" = "74 - Ride [DSP]";
            "75" = "75 - OH L [DSP]";
            "76" = "76 - OH R [DSP]";
            "77" = "77 - Room L [DSP]";
            "78" = "78 - Room R [DSP]";
            "79" = "79 - Lead Mic L [DSP]";
            "80" = "80 - Lead Mic R [DSP]";
            "81" = "81 - Engineer Vocal [DSP]";
            "82" = "82 - Drummer Mic [DSP]";
            "83" = "83 - Bass Talkback [DSP]";
            "84" = "84 - Guitar 1 Talkback [DSP]";
            "85" = "85 - Guitar 2 Talkback [DSP]";
            "86" = "86 - Keys 1 Talkback [DSP]";
            "87" = "87 - Keys 2 Talkback [DSP]";
            "88" = "88 - Wireless Mic 1 [DSP]";
            "89" = "89 - Wireless Mic 2 [DSP]";
            "90" = "90 - Producer Talkback [DSP]";
            "91" = "91 - Generic Talkback [DSP]";
            "92" = "92 - Bass DI [DSP]";
            "93" = "93 - Bass Amp [DSP]";
            "94" = "94 - Broadcast Master L [DSP]";
            "95" = "95 - Broadcast Master R [DSP]";
            "96" = "96 - Engineer Alt Vocal/Talkback [DSP]";
            "97" = "97 - System L";
            "98" = "98 - System R";
            "99" = "99 - System Notifications L";
            "100" = "100 - System Notifications R";
            "101" = "101 - Voice Chat L";
            "102" = "102 - Voice Chat R";
            "103" = "103 - DAW L";
            "104" = "104 - DAW R";
            "105" = "105 - Talkback L";
            "106" = "106 - Talkback R";
            "107" = "107 - Speakers L";
            "108" = "108 - Speakers R";
            "109" = "109 - Engineer Mix L";
            "110" = "110 - Engineer Mix R";
            "111" = "111 - Vocal 1 Mix L";
            "112" = "112 - Vocal 1 Mix R";
            "113" = "113 - Click";
            "114" = "114 - Guide";
            "115" = "115 - Drums Mix L";
            "116" = "116 - Drums Mix R";
            "117" = "117 - Bass Mix L";
            "118" = "118 - Bass Mix R";
            "119" = "119 - Guitar 1 Mix L";
            "120" = "120 - Guitar 1 Mix R";
            "121" = "121 - Guitar 2 Mix L";
            "122" = "122 - Guitar 2 Mix R";
            "123" = "123 - Keys 1 Mix L";
            "124" = "124 - Keys 1 Mix R";
            "125" = "125 - Keys 2 Mix L";
            "126" = "126 - Keys 2 Mix R";
            "127" = "127 - Broadcast Mix L";
            "128" = "128 - Broadcast Mix R";
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
            "53" = "53 - OUT53";
            "54" = "54 - OUT54";
            "55" = "55 - OUT55";
            "56" = "56 - OUT56";
            "57" = "57 - OUT57";
            "58" = "58 - OUT58";
            "59" = "59 - OUT59";
            "60" = "60 - OUT60";
            "61" = "61 - OUT61";
            "62" = "62 - OUT62";
            "63" = "63 - OUT63";
            "64" = "64 - OUT64";
            "65" = "65 - OUT65";
            "66" = "66 - OUT66";
            "67" = "67 - OUT67";
            "68" = "68 - OUT68";
            "69" = "69 - OUT69";
            "70" = "70 - OUT70";
            "71" = "71 - OUT71";
            "72" = "72 - OUT72";
            "73" = "73 - OUT73";
            "74" = "74 - OUT74";
            "75" = "75 - OUT75";
            "76" = "76 - OUT76";
            "77" = "77 - OUT77";
            "78" = "78 - OUT78";
            "79" = "79 - OUT79";
            "80" = "80 - OUT80";
            "81" = "81 - OUT81";
            "82" = "82 - OUT82";
            "83" = "83 - OUT83";
            "84" = "84 - OUT84";
            "85" = "85 - OUT85";
            "86" = "86 - OUT86";
            "87" = "87 - OUT87";
            "88" = "88 - OUT88";
            "89" = "89 - OUT89";
            "90" = "90 - OUT90";
            "91" = "91 - OUT91";
            "92" = "92 - OUT92";
            "93" = "93 - OUT93";
            "94" = "94 - OUT94";
            # 95-96: Reaper master output. Reaper's hardware outputs 95/96
            # land here via the daw → daw_to_inferno → Inferno TX 1:1 map.
            # Galaxy 32 RX 59/60 are renamed "DAW L/R" and subscribed to
            # this pair.
            "95" = "DAW L";
            "96" = "DAW R";
            # 97-98: System audio mix sent to Galaxy 32 RX 61/62 ("System L/R").
            # Notifications are NOT mixed in at the Dante level — they mix
            # into system_audio inside PipeWire before this TX, so the
            # `games` sink (which shares TX 97/98 via studioRoutedSinks) is
            # the clean, notification-free signal OBS captures for screen
            # recordings.
            "97" = "System L";
            "98" = "System R";
            "99" = "99 - OUT99";
            "100" = "100 - OUT100";
            # 101-102: chat / call audio → Galaxy 32 RX 63/64 ("Voice Chat L/R").
            "101" = "Voice Chat L";
            "102" = "Voice Chat R";
            "103" = "103 - OUT103";
            "104" = "104 - OUT104";
            "105" = "105 - OUT105";
            "106" = "106 - OUT106";
            "107" = "107 - OUT107";
            "108" = "108 - OUT108";
            "109" = "109 - OUT109";
            "110" = "110 - OUT110";
            "111" = "111 - OUT111";
            "112" = "112 - OUT112";
            "113" = "113 - OUT113";
            "114" = "114 - OUT114";
            "115" = "115 - OUT115";
            "116" = "116 - OUT116";
            "117" = "117 - OUT117";
            "118" = "118 - OUT118";
            "119" = "119 - OUT119";
            "120" = "120 - OUT120";
            "121" = "121 - OUT121";
            "122" = "122 - OUT122";
            "123" = "123 - OUT123";
            "124" = "124 - OUT124";
            "125" = "125 - OUT125";
            "126" = "126 - OUT126";
            "127" = "127 - OUT127";
            "128" = "128 - OUT128";
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
