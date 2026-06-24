{
  inputs,
  fleet,
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
          preferredLeader = "AA-4202524000109";
          # MUST stay "debug" (or "trace"): at "warn" this statime fork loses a
          # startup race — it hits the announce-receipt timeout and self-promotes
          # to a PTPv1 master (unimplemented stub) before processing the leader's
          # first Sync, so the clock never locks and no Dante audio flows. The
          # extra per-packet logging delay lets the Sync win the race. Heisenbug.
          loglevel = "debug";
          # When the watchdog recovers a lost PTP lock, re-open the Inferno
          # PipeWire node against the now-valid clock (otherwise it stays frozen
          # in "init"). studio-routing-links is partOf wireplumber and re-wires.
          reinitOnRecovery = [ "wireplumber.service" ];
        })
        (fleet.music._.production._.inferno {
          bindIp = "10.10.10.10";
          deviceId = "00000A0A0A0A0001";
          channels = 128;
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

        # Forgejo Actions runner. Picks up CI jobs from
        # https://git.starcommand.live and executes them here so
        # starcommand (the always-on Forgejo host) doesn't have to
        # bear compile / test / lint load. Token lives in
        # hosts/THEBATTLESHIP/secrets.yaml under `forgejo/runner_token`.
        (fleet.selfhost._.forgejo-runner {
          tokenSopsFile = "${inputs.nix-secrets}/sops/hosts/THEBATTLESHIP.yaml";
        })

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
      ];

      nixos =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          # Studio routing channel map. One source of truth for both the
          # PipeWire loopback definitions and the studio-routing-links
          # systemd oneshot. Channel numbers reference the
          # THEBATTLESHIP.ReaperChanMap entries on Inferno TX/RX.
          # `fanout` (optional) is a list of additional Audio/Sink targets
          # that should also receive a copy of the sink's stereo signal,
          # wired from the loopback's capture-side `monitor_1/2` ports.
          # Used so e.g. System Audio plays *both* into the Dante TX
          # channels and out of the Yamaha TF console for local monitoring
          # without needing the Dante side to be wired up.
          yamahaTF = "alsa_output.usb-Yamaha_Corporation_Yamaha_TF-00.playback.0.0";
          studioRoutedSinks = [
            {
              name = "system_audio";
              desc = "System Audio";
              txL = 97;
              txR = 98;
              fanout = [
                {
                  node = yamahaTF;
                  portL = "playback_1";
                  portR = "playback_2";
                }
              ];
            }
            # System notifications are a sink-only node (no Dante TX). Its
            # monitor feeds into system_audio so the user hears the chime
            # alongside other system audio on the Dante speakers, but the
            # `games` sink (which OBS records) doesn't see notifications
            # because the mix happens upstream of the games tap.
            {
              name = "system_notifications";
              desc = "System Notifications";
              feedsInto = "system_audio";
              fanout = [ ];
            }
            {
              name = "voice_chat";
              desc = "Voice Chat";
              txL = 101;
              txR = 102;
              fanout = [ ];
            }
            # Games shares TX with System Audio but stays a separate
            # Audio/Sink so OBS / recordings can capture Games alone.
            {
              name = "games";
              desc = "Games";
              txL = 97;
              txR = 98;
              fanout = [ ];
            }
          ];
          studioRoutedSources = [
            {
              name = "talkback_mic";
              desc = "Talkback Mic";
              rxL = 51;
              rxR = 52;
            }
            {
              name = "talkback_mic_dsp";
              desc = "Talkback Mic [DSP]";
              rxL = 90;
              rxR = 91;
            }
          ];

          # Starcommand hosts Nextcloud. Keep the WebDAV URL on the canonical
          # TLS hostname, but resolve it to Starcommand's 10G/Dante address on
          # THEBATTLESHIP so traffic stays on the direct 10.10 link.
          nextcloudWebdavHost = "cloud.starcommand.live";
          nextcloudWebdavUser = "codywright";
          nextcloudWebdavMount = "/mnt/nextcloud/codywright";
          nextcloudNfsFilesMount = "/mnt/starcommand/Operations/nextcloud-data/data/${nextcloudWebdavUser}/files";
          nextcloudWebdavMediaMount = "/run/media/starcommand";
          nextcloudWebdavUrl = "https://${nextcloudWebdavHost}/remote.php/dav/files/${nextcloudWebdavUser}/";
        in
        {
          time.timeZone = "America/Los_Angeles";
          boot.loader.grub.configurationLimit = 3;
          services.dbus.implementation = "dbus";

          # Prevent Intel I226-V (igc/enp11s0) PCIe link loss after extended uptime.
          # The I226-V has a hardware errata where the NIC self-initiates PCIe L1
          # substates independently of host ASPM, causing "PCIe link lost, device
          # now detached" after hours of uptime. pci=nommconf forces I/O port access
          # for PCI config space instead of MMIO, working around the link-drop bug.
          boot.kernelParams = [
            "pcie_aspm=off"
            "pci=nommconf"
            # Never auto-suspend USB — the TF audio interface must not be
            # power-managed mid-session.
            "usbcore.autosuspend=-1"
          ];

          # ── Low-latency audio (user-level PipeWire) ──────────────────────────
          # PREEMPT_RT real-time kernel on mainline 6.18 (CONFIG_PREEMPT_RT).
          # Cuts worst-case scheduling jitter (~500 µs generic → <100 µs RT) — the
          # real limiter on minimum audio buffer size. Build-tested: Nvidia 595.x
          # compiles against it. PREEMPT_DYNAMIC off (mutually exclusive with RT).
          boot.kernelPackages = lib.mkForce (
            pkgs.linuxPackagesFor (
              pkgs.linux_6_18.override {
                structuredExtraConfig = with lib.kernel; {
                  PREEMPT_RT = yes;
                  PREEMPT_DYNAMIC = lib.mkForce no;
                };
                ignoreConfigErrors = true;
              }
            )
          );

          # Hold CPU PM-QoS DMA latency at 0 — disables the deep C-states that add
          # CPU wakeup jitter (AMD's are aggressive). The wakeup-latency half of
          # the jitter floor; the RT kernel is the other half.
          systemd.services.cpu-dma-latency = {
            description = "Pin cpu_dma_latency to 0 (no deep C-states) for low audio jitter";
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              Type = "simple";
              Restart = "always";
              ExecStart = ''${pkgs.python3}/bin/python3 -c "import os,struct,signal; fd=os.open('/dev/cpu_dma_latency', os.O_WRONLY); os.write(fd, struct.pack('i', 0)); signal.pause()"'';
            };
          };

          # Raise RT priority of the threaded xHCI USB IRQ handlers so the TF's USB
          # completions aren't preempted (threadirqs makes these kernel threads).
          systemd.services.audio-usb-irq-prio = {
            description = "Bump xHCI USB IRQ threads to RT priority for audio";
            wantedBy = [ "multi-user.target" ];
            after = [ "multi-user.target" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
            };
            script = ''
              for pid in $(${pkgs.procps}/bin/ps -eLo pid=,comm= \
                  | ${pkgs.gnugrep}/bin/grep -E 'irq/[0-9]+-xhci' \
                  | ${pkgs.gawk}/bin/awk '{print $1}'); do
                ${pkgs.util-linux}/bin/chrt -f -p 85 "$pid" 2>/dev/null || true
              done
            '';
          };

          # Disable Energy Efficient Ethernet on the I226-V — EEE interaction
          # with PCIe L1 substates errata triggers spontaneous link loss.
          # The boot-time oneshot below covers the initial bring-up, and the
          # udev rule re-applies EEE=off every time the kernel binds the
          # interface (after a PCIe rescan, suspend/resume, or NM bouncing
          # the link), since NetworkManager has been observed to re-enable EEE
          # on its own activations.
          systemd.services."igc-disable-eee" = {
            description = "Disable EEE on Intel I226-V (enp11s0) to prevent PCIe link drops";
            after = [ "network-online.target" ];
            wants = [ "network-online.target" ];
            wantedBy = [ "multi-user.target" ];
            script = "${pkgs.ethtool}/bin/ethtool --set-eee enp11s0 eee off || true";
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
            };
          };

          services.udev.extraRules = ''
            # Re-disable EEE every time the igc driver binds an I226-V (vendor
            # 8086, device 125c). Matches on add+change so it fires after PCIe
            # rescans and NetworkManager link cycles.
            ACTION=="add|change", SUBSYSTEM=="net", DRIVERS=="igc", ATTRS{vendor}=="0x8086", ATTRS{device}=="0x125c", RUN+="${pkgs.ethtool}/bin/ethtool --set-eee %k eee off"

            # Keychron K2 HE registers a HID joystick interface that claims js0,
            # bumping real gamepads to controller 2 in Steam. Strip joystick from
            # its input class so it stays a keyboard/mouse only.
            SUBSYSTEMS=="usb", ATTRS{idVendor}=="3434", ATTRS{idProduct}=="0e20", ENV{ID_INPUT_JOYSTICK}="", ENV{ID_INPUT_KEY}="1"
          '';

          # ethtool is added alongside iw/tcpdump/etc in the dedicated
          # environment.systemPackages block lower in this file (search for
          # "ethtool" there). Keep that single definition to avoid a second
          # mergeable assignment in the same module.

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

          environment.variables = {
            TASK_VAULT = "${nextcloudWebdavMediaMount}/Projects";
            TASK_SERVER = "http://10.10.10.1:3456";
            NEXTCLOUD_URL = "https://cloud.starcommand.live";
            NEXTCLOUD_USER = "codywright";
            NEXTCLOUD_PASSWORD_FILE = config.sops.secrets."cody/task/nextcloud-password".path;
          };

          sops.secrets."cody/task/nextcloud-password" = {
            owner = "cody";
            group = "users";
            mode = "0400";
          };

          # ext4 games partition
          # Keep it non-blocking so a missing/offline drive never drops the
          # machine into emergency mode during boot.
          fileSystems."/run/media/GAMES" = {
            device = "/dev/disk/by-uuid/50936b56-bf07-42eb-b345-ad21ba710525";
            fsType = "ext4";
            options = [
              "rw"
              "noauto"
              "nofail"
              "x-systemd.automount"
              "x-systemd.device-timeout=10"
              "x-systemd.idle-timeout=600"
            ];
          };

          # ext4 audio production partition
          fileSystems."/run/media/AudioHaven" = {
            device = "/dev/disk/by-uuid/a9ef263a-2ad2-4988-8f02-188061dc0228";
            fsType = "ext4";
            options = [
              "rw"
              "nofail"
            ];
          };

          # ext4 dedicated development partition (Samsung 990 EVO Plus 2TB)
          fileSystems."/run/media/Development" = {
            device = "/dev/disk/by-uuid/7e6024ba-a396-409f-92ae-27d74359240d";
            fsType = "ext4";
            options = [
              "rw"
              "nofail"
            ];
          };

          systemd.services.development-permissions = {
            description = "Ensure Development is writable by cody";
            wantedBy = [ "run-media-Development.mount" ];
            after = [ "run-media-Development.mount" ];
            bindsTo = [ "run-media-Development.mount" ];
            serviceConfig.Type = "oneshot";
            script = ''
              chown cody:users /run/media/Development
              chmod 0775 /run/media/Development
            '';
          };

          systemd.services.audiohaven-permissions = {
            description = "Ensure AudioHaven is writable by cody";
            wantedBy = [ "run-media-AudioHaven.mount" ];
            after = [ "run-media-AudioHaven.mount" ];
            bindsTo = [ "run-media-AudioHaven.mount" ];
            serviceConfig.Type = "oneshot";
            script = ''
              chown cody:users /run/media/AudioHaven
              chmod 0775 /run/media/AudioHaven
            '';
          };

          # Starcommand services over the 10G LAN. Keep public/certificate-valid
          # hostnames in URLs, but pin them to Starcommand's 10.10.10.1 address
          # locally so THEBATTLESHIP talks directly to nginx instead of hairpinning
          # through Cloudflare Tunnel.
          networking.hosts."10.10.10.1" = [
            "starcommand.live"
            "agent.starcommand.live"
            "audiobooks.starcommand.live"
            "auth.starcommand.live"
            "bazarr.starcommand.live"
            "bookmarks.starcommand.live"
            "chat.starcommand.live"
            "cloud.starcommand.live"
            "finance.starcommand.live"
            "git.starcommand.live"
            "grafana.starcommand.live"
            "grocy.starcommand.live"
            "hermes.starcommand.live"
            "home.starcommand.live"
            "invoice.starcommand.live"
            "jackett.starcommand.live"
            "jdownloader.starcommand.live"
            "ldap.starcommand.live"
            "lidarr.starcommand.live"
            "media.starcommand.live"
            "office.starcommand.live"
            "photos.starcommand.live"
            "radarr.starcommand.live"
            "readarr.starcommand.live"
            "signaling.starcommand.live"
            "sonarr.starcommand.live"
            "task-preview.starcommand.live"
            "task.starcommand.live"
            "torrents.starcommand.live"
            "vault.starcommand.live"
            "workspace.starcommand.live"
            "youtube.starcommand.live"
            "invoice.fasttrackaudio.com"
          ];
          services.davfs2 = {
            enable = true;
            settings.globalSection = {
              # Nextcloud works best with davfs2 client-side LOCKs disabled;
              # the server still performs normal Nextcloud/WebDAV conflict handling.
              use_locks = false;
            };
          };
          environment.etc."davfs2/secrets".source = config.sops.secrets."cody/nextcloud/davfs2-secrets".path;
          fileSystems."${nextcloudWebdavMount}" = {
            device = nextcloudWebdavUrl;
            fsType = "davfs";
            options = [
              "rw"
              "noauto"
              "nofail"
              "_netdev"
              "x-systemd.automount"
              "x-systemd.idle-timeout=600"
              "x-systemd.requires=network-online.target"
              "x-systemd.after=network-online.target"
              "x-systemd.requires=run-secrets.d.mount"
              "x-systemd.after=run-secrets.d.mount"
              "uid=1000"
              "gid=100"
              "file_mode=0664"
              "dir_mode=0775"
            ];
          };

          fileSystems."${nextcloudWebdavMediaMount}" = {
            device = nextcloudNfsFilesMount;
            fsType = "none";
            options = [
              "bind"
              # noauto + automount: do NOT pull this bind mount in at boot.
              # Without these it mounts as part of remote-fs.target, which
              # (via the requires below) triggers the mnt-starcommand NFS mount
              # during boot. When the 10G/Dante network isn't up yet that NFS
              # mount times out (30s) and fails this dependency, stalling boot.
              # As an automount it only activates on first access instead.
              "noauto"
              "nofail"
              "_netdev"
              "x-systemd.automount"
              "x-systemd.idle-timeout=600"
              "x-systemd.requires=mnt-starcommand.mount"
              "x-systemd.after=mnt-starcommand.mount"
            ];
          };

          # Davfs2 reads credentials from /etc/davfs2/secrets. This SOPS secret
          # should contain exactly one line, for example:
          #   /mnt/nextcloud/codywright codywright <nextcloud-app-password>
          # The user-facing /run/media/starcommand mount uses the faster 10G
          # NFS view of the same Nextcloud files. Keep davfs2 available at
          # /mnt/nextcloud/codywright only for explicit WebDAV testing.
          # Do not put the app password directly in Nix; keep it in SOPS.

          # Mount starcommand storage over 10G NFS
          fileSystems."/mnt/starcommand" = {
            device = "10.10.10.1:/";
            fsType = "nfs";
            options = [
              "nfsvers=4.2"
              "rsize=1048576"
              "wsize=1048576"
              "_netdev"
              "noauto"
              "x-systemd.automount"
              "x-systemd.idle-timeout=600"
              "x-systemd.mount-timeout=30"
              "nofail"
              "soft"
              "timeo=150"
              "retrans=3"
            ];
          };

          programs.ssh.knownHosts."10.10.10.1" = {
            publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIENFHgs8JqCE4/dO58AN8W4M2SRgetgar94m2ntI9xb8";
          };

          # Hermes workspace on THEBATTLESHIP for remote SSH execution from starcommand.
          # The agent user lands in /home/cody/agent and gets symlinks to the source
          # trees it most commonly needs without having to bounce between shells.
          systemd.tmpfiles.rules = [
            "d /mnt/nextcloud 0755 root root -"
            "d ${nextcloudWebdavMount} 0775 cody users -"
            "d ${nextcloudWebdavMediaMount} 0775 cody users -"
            "d /home/cody/agent 0755 cody users -"
            "L+ /home/cody/agent/.starcommand 0644 cody users - /home/cody/.starcommand"
            "L+ /home/cody/agent/.flake 0644 cody users - /home/cody/.flake"
            "L+ /home/cody/agent/Task 0644 cody users - /home/cody/Development/Task"
            "L+ /home/cody/agent/wiki 0644 cody users - ${nextcloudWebdavMount}"
          ];

          users.users.cody.openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFrMb6rGjMO0EzWfkG71kYnkbtxW5+oIUCyaum3uHViW agent@starcommand"
          ];
          # SOPS secrets
          imports = [ inputs.sops-nix.nixosModules.default ];
          sops = {
            defaultSopsFile = "${inputs.nix-secrets}/sops/users/cody.yaml";
            validateSopsFiles = false;
            age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
            # Bootstrap cody's age key from the host secret so home-manager
            # sops works without manually copying sops.key around.
            secrets."keys/age" = {
              sopsFile = "${inputs.nix-secrets}/sops/hosts/THEBATTLESHIP.yaml";
              owner = "cody";
              path = "/home/cody/.config/sops/age/keys.txt";
            };
            secrets."cody/nextcloud/davfs2-secrets" = {
              owner = "root";
              group = "root";
              mode = "0400";
            };
            secrets."cody/proton/privatekey" = {
              owner = "root";
              group = "root";
              mode = "0400";
            };

            # FastTrackStudio Codeberg agent credentials.
            # Codeberg API/git access token — decrypted to a file owned by cody.
            secrets."cody/codeberg/fts-codeberg-access-token" = {
              owner = "cody";
              group = "users";
              mode = "0400";
            };
            # Dedicated SSH key for the fts-agent Codeberg account (the public
            # half is registered on that account). Used as an SSH IdentityFile.
            secrets."cody/codeberg/fts-agent" = {
              owner = "cody";
              group = "users";
              mode = "0400";
            };

            # Render the token into a dotenv file so any service can pull it in
            # via `serviceConfig.EnvironmentFile`, and it's available to source
            # for ad-hoc use — without the value ever landing in the nix store.
            # Path: config.sops.templates."fts-codeberg.env".path
            templates."fts-codeberg.env" = {
              content = ''
                FTS_CODEBERG_ACCESS_TOKEN=${config.sops.placeholder."cody/codeberg/fts-codeberg-access-token"}
                FTS_CODEBERG_GIT_URL=https://fts-agent:${
                  config.sops.placeholder."cody/codeberg/fts-codeberg-access-token"
                }@codeberg.org
              '';
              owner = "cody";
              group = "users";
              mode = "0400";
            };
          };

          # --- Virtual PipeWire routing nodes ---
          #
          # Every multichannel node (Inferno + the studio loopbacks) declares
          # plain numeric channels via `audio.position = ["UNK", …]`, so the
          # ports come out as `playback_N` / `capture_N` / `input_N` /
          # `output_N` instead of FL/FR/AUX… — easier to reason about and
          # required for explicit port-by-port linking by name. Specific
          # channel pairs are then wired by the `studio-routing-links`
          # systemd oneshot below using `pw-link`. WirePlumber 0.5 has no
          # static-link config, and PipeWire's `context.objects` link-
          # factory creation is fatal-on-missing-port at startup, so a
          # post-pipewire oneshot with retries is the reliable pattern.

          services.pipewire =
            let
              numericPos = n: lib.replicate n "UNK";

              # `node.autoconnect = false` tells WirePlumber's linking
              # policy to skip the node entirely; without it WP picks the
              # default sink as a target and grows the loopback's port
              # count to match (128). The link-factory pins are the only
              # things allowed to wire these ends.
              dontAutoconnect = {
                "node.autoconnect" = false;
                "node.dont-reconnect" = true;
              };
              mkRoutedSink =
                s@{
                  name,
                  desc,
                  txL ? null,
                  txR ? null,
                  feedsInto ? null,
                  fanout ? [ ],
                }:
                {
                  name = "libpipewire-module-loopback";
                  args = {
                    "node.description" = desc;
                    "capture.props" = {
                      "node.name" = name;
                      "node.description" = desc;
                      "media.class" = "Audio/Sink";
                      "audio.channels" = 2;
                      "audio.position" = numericPos 2;
                      "monitor.channel-volumes" = true;
                      "node.pause-on-idle" = false;
                    };
                    "playback.props" =
                      dontAutoconnect
                      // (
                        if feedsInto != null then
                          # No Dante TX — playback side is a dummy. The actual
                          # local feed into the target sink is wired by the
                          # studio-routing-links service via pw-link.
                          {
                            "node.name" = "${name}_sink_back";
                            "node.description" = desc;
                            "audio.channels" = 2;
                            "audio.position" = numericPos 2;
                            "node.passive" = true;
                          }
                        else
                          {
                            "node.name" = "${name}_to_inferno";
                            "node.description" = "${desc} → Inferno TX ${toString txL}/${toString txR}";
                            "audio.channels" = 2;
                            "audio.position" = numericPos 2;
                            "node.passive" = true;
                          }
                      );
                  };
                };
              mkRoutedSource =
                {
                  name,
                  desc,
                  rxL,
                  rxR,
                }:
                {
                  name = "libpipewire-module-loopback";
                  args = {
                    "node.description" = desc;
                    "capture.props" = dontAutoconnect // {
                      "node.name" = "${name}_from_inferno";
                      "node.description" = "Inferno RX ${toString rxL}/${toString rxR} → ${desc}";
                      "audio.channels" = 2;
                      "audio.position" = numericPos 2;
                      "node.passive" = true;
                    };
                    "playback.props" = {
                      "node.name" = name;
                      "node.description" = desc;
                      "media.class" = "Audio/Source";
                      "audio.channels" = 2;
                      "audio.position" = numericPos 2;
                      "node.passive" = true;
                    };
                  };
                };

              routedSinks = studioRoutedSinks;
              routedSources = studioRoutedSources;
            in
            {
              # libpipewire-jack auto-connects every JACK client output
              # port to the *default Audio/Sink* during jack_client_open(),
              # which is too early for any WirePlumber `node.rules` to
              # influence. Pin the target via jack.rules so every JACK
              # client lands on the `daw` 128-channel proxy sink. From
              # there, studio-routing-links wires daw_to_inferno into
              # specific Inferno TX channels (DAW L/R = TX 95/96).
              extraConfig.jack."93-studio-jack-target" = {
                "jack.properties" = {
                  "node.target" = "daw";
                };
                "jack.rules" = [
                  {
                    matches = [
                      { "application.process.binary" = "reaper"; }
                      { "application.name" = "REAPER"; }
                      { "node.name" = "REAPER"; }
                    ];
                    actions.update-props = {
                      "node.target" = "daw";
                      "target.object" = "daw";
                      # Belt-and-suspenders: turn the JACK auto-connect off
                      # for this client so even if `node.target` is ignored
                      # by the shim, we don't get spurious Inferno-direct
                      # links re-created on every port registration.
                      "jack.connect" = false;
                    };
                  }
                ];
              };

              extraConfig.pipewire."93-studio-virtual-nodes" = {
                "context.modules" = [
                  # 128-ch DAW pass-through for Reaper. Linked 1:1 into
                  # Inferno sink by the link factories below.
                  {
                    name = "libpipewire-module-loopback";
                    args = {
                      "node.description" = "DAW";
                      "capture.props" = {
                        "node.name" = "daw";
                        "node.description" = "DAW";
                        "media.class" = "Audio/Sink";
                        "audio.channels" = 128;
                        "audio.position" = numericPos 128;
                        "node.pause-on-idle" = false;
                        # Inferno sink sets priority.session = 2000 to win
                        # default-sink election; that makes PipeWire's JACK
                        # shim auto-connect every Reaper output directly to
                        # Inferno sink, bypassing the `daw` proxy. Pin daw
                        # to 3000 so Reaper lands here and the channel
                        # renames on daw_to_inferno actually apply.
                        "priority.session" = 3000;
                        "priority.driver" = 3000;
                      };
                      "playback.props" = dontAutoconnect // {
                        "node.name" = "daw_to_inferno";
                        "audio.channels" = 128;
                        "audio.position" = numericPos 128;
                        "node.passive" = true;
                      };
                    };
                  }
                  # 128-ch DAW input proxy — the mirror of `daw` for the
                  # capture direction. `daw_from_inferno` is the upstream
                  # leg whose inputs studio-routing-links wires 1:1 from
                  # Inferno source's capture ports, and `daw_inputs` is
                  # the Audio/Source the DAW (Reaper / Ardour / Bitwig)
                  # actually opens for recording. Keeping the daw side
                  # isolated from the Inferno source node means the
                  # daw-router rewriter has a single canonical target
                  # for any erroneous reaper:in_N -> {Yamaha capture,
                  # Inferno source, …} links.
                  {
                    name = "libpipewire-module-loopback";
                    args = {
                      "node.description" = "DAW Inputs";
                      "capture.props" = dontAutoconnect // {
                        "node.name" = "daw_from_inferno";
                        "node.description" = "Inferno → DAW";
                        "audio.channels" = 128;
                        "audio.position" = numericPos 128;
                        "node.passive" = true;
                      };
                      "playback.props" = {
                        "node.name" = "daw_inputs";
                        "node.description" = "DAW Inputs";
                        "media.class" = "Audio/Source";
                        "audio.channels" = 128;
                        "audio.position" = numericPos 128;
                        "node.pause-on-idle" = false;
                        "priority.session" = 3000;
                        "priority.driver" = 3000;
                      };
                    };
                  }
                ]
                ++ map mkRoutedSink routedSinks
                ++ map mkRoutedSource routedSources;
              };

              wireplumber.extraConfig."80-pro-audio-usb"."monitor.alsa.rules" = [
                {
                  matches = [
                    { "device.name" = "alsa_card.usb-Yamaha_Corporation_Yamaha_TF-00"; }
                    { "device.name" = "~alsa_card.usb-Fractal_Audio.*"; }
                  ];
                  actions.update-props."api.alsa.use-acp" = false;
                }
                {
                  # The TF is a fixed 34x34 interface. Without an explicit
                  # channel count, raw-mode probing requests the spa-alsa
                  # default (64), fails repeatedly ("Channels doesn't match
                  # (requested 64, got 34)") and stretches the device-churn
                  # window in which pipewire 1.6's link-creation lock race
                  # can deadlock the core under a connecting JACK client
                  # (REAPER stuck on launch).
                  matches = [
                    { "node.name" = "~alsa_(output|input)\\.usb-Yamaha_Corporation_Yamaha_TF.*"; }
                  ];
                  actions.update-props = {
                    "audio.channels" = 34;
                    # Keep the TF node instantiated even when idle. The
                    # local monitoring path is a set of pw-link pins from
                    # system_audio/games/voice_chat:monitor → TF:playback
                    # (studio-local-links below). If the device suspends on
                    # idle, those ports vanish and the links are silently
                    # dropped — audio then "works for a few seconds then
                    # cuts out" until something re-wires. Never suspend it.
                    "session.suspend-timeout-seconds" = 0;
                    "node.always-process" = true;
                    # Low-latency attempt: small ALSA period (256) but several
                    # periods, so the device ring (period-size × period-num) still
                    # buffers the congested USB hub's packet starvation while the
                    # graph quantum stays low. Raise period-num if it glitches.
                    "api.alsa.period-size" = 256;
                    "api.alsa.period-num" = 3;
                    "api.alsa.headroom" = 128;
                  };
                }
              ];

              # Make the `system_audio` virtual sink the default so every
              # app funnels through it. studio-local-links fans system_audio
              # (plus games/voice_chat) out to the Yamaha TF for local
              # monitoring regardless of whether the Dante stack is up, and
              # the dante-gated studio-routing-links adds the Inferno TX legs
              # on top when `dante on`.
              wireplumber.extraConfig."10-studio-defaults".wireplumber.settings = {
                "default.configured.audio.sink" = "system_audio";
              };

              # Graph quantum = latency. Lowered from the old 1024 (~21 ms USB-
              # congestion workaround) to 256 (~5.3 ms) for low latency. The TF
              # still shares a congested nested USB hub (Insta360 + KONTROL S88 +
              # Stream Deck) where isochronous packets starve and glitch *below*
              # the ALSA layer (no xruns logged), so the mitigation moves to the
              # ALSA side: a small period with several periods (see the TF rule in
              # 80-pro-audio-usb above) buffers the bus starvation without the big
              # latency hit. If it still crackles, raise api.alsa.period-num — or
              # move the TF to its own direct USB port (the real fix). mkForce
              # because the audio facet's default pipewire instance also sets this.
              extraConfig.pipewire."92-low-latency".context.properties."default.clock.quantum" = lib.mkForce 256;

              # Disable the libcamera monitor. WirePlumber publishes every UVC
              # webcam + the MS2109 HDMI grabber as BOTH a libcamera node and a
              # v4l2 node; its built-in dedup is documented to fail on
              # multi-interface / "complex" devices (the grabber especially), so
              # two readers end up contending for one /dev/videoN — the cause of
              # OBS's "decoder: failed to unpack jpeg" and "select timed out".
              # Dropping libcamera leaves exactly one (v4l2, media.role=Camera)
              # node per device, which is what both the direct-V4L2 path and the
              # xdg-desktop-portal Camera path want. Per-user WirePlumber uses
              # the "main" profile.
              wireplumber.extraConfig."51-disable-libcamera"."wireplumber.profiles" = {
                main."monitor.libcamera" = "disabled";
              };

              # Belt-and-suspenders: in case the per-loopback `node.autoconnect`
              # property doesn't make it through libpipewire-module-loopback's
              # adapter init, also pin the same flag from WirePlumber by name.
              wireplumber.extraConfig."95-studio-no-autolink"."node.rules" = [
                {
                  matches = [
                    { "node.name" = "~.*_to_inferno"; }
                    { "node.name" = "~.*_from_inferno"; }
                  ];
                  actions.update-props = {
                    "node.autoconnect" = false;
                    "node.dont-reconnect" = true;
                  };
                }
              ];

              # Pin Reaper (and other JACK clients with DSP role) to the
              # `daw` Audio/Sink instead of letting wireplumber auto-route
              # them to "Inferno sink" — which it does today because Inferno
              # sink has priority.session = 2000 and is the only ≥128-channel
              # sink in the graph. Sending Reaper through `daw` is what
              # studioRoutedSinks / studio-routing-links assume: daw's
              # capture is the entry point, `daw_to_inferno` is its proxy
              # to Dante, and bypassing it means the channel renaming on
              # daw_to_inferno never applies to Reaper's signal.
              wireplumber.extraConfig."96-reaper-to-daw"."node.rules" = [
                {
                  matches = [
                    { "node.name" = "REAPER"; }
                    { "application.name" = "REAPER"; }
                  ];
                  actions.update-props = {
                    "target.object" = "daw";
                    "node.target" = "daw";
                  };
                }
              ];
            };

          # --- Studio routing link service ---
          #
          # Walks every (out, in) port pair derived above and wires it via
          # `pw-link`. Idempotent: pw-link refuses to create a duplicate
          # link, and if a pair fails (because the node hasn't registered
          # yet) the loop retries until either both nodes exist or the
          # 60-second budget runs out.
          # WirePlumber persists "which profile is active for each card" in
          # ~pipewire/.local/state/wireplumber/default-profile. If a card's
          # entry says `off`, WP refuses to instantiate any sink/source for
          # it. We want the Yamaha TF console and the Ryzen onboard analog
          # to come up active on every boot, so seed those entries before
          # wireplumber starts. Cards we don't list (e.g. the Axe-Fx) keep
          # whatever the file previously had.
          systemd.user.services.wireplumber.serviceConfig.ExecStartPre =
            let
              seedScript = pkgs.writeShellScript "wireplumber-seed-profiles" ''
                set -u
                state="''${XDG_STATE_HOME:-$HOME/.local/state}/wireplumber/default-profile"
                mkdir -p "$(dirname "$state")"
                touch "$state"

                # Each (card-name, profile) pair we want enforced.
                declare -A want=(
                  ["alsa_card.usb-Yamaha_Corporation_Yamaha_TF-00"]="on"
                  ["alsa_card.pci-0000_7a_00.6"]="output:analog-stereo+input:analog-stereo"
                )

                tmp=$(mktemp)
                # Keep the [default-profile] header and any keys we don't manage.
                if grep -q '^\[default-profile\]' "$state"; then
                  cp "$state" "$tmp"
                else
                  echo '[default-profile]' > "$tmp"
                fi

                for k in "''${!want[@]}"; do
                  v="''${want[$k]}"
                  if grep -qE "^$k=" "$tmp"; then
                    ${pkgs.gnused}/bin/sed -i "s|^$k=.*|$k=$v|" "$tmp"
                  else
                    echo "$k=$v" >> "$tmp"
                  fi
                done

                install -m 0644 "$tmp" "$state"
                rm -f "$tmp"
              '';
            in
            [ "${seedScript}" ];

          # --- Local monitoring link service (always on) ---
          #
          # Fans the user-facing virtual sinks out to the Yamaha TF console
          # for local monitoring, independent of the Dante stack. This is
          # what makes the box usable with `dante off`: apps land on
          # `system_audio` (the default sink, set above), and these pw-link
          # pins carry system_audio/games/voice_chat:monitor_1/2 →
          # TF:playback_1/2 so audio reaches the console with no Inferno/PTP
          # involvement.
          #
          # Deliberately NOT gated behind dante.target, and with no Inferno
          # node wait (unlike studio-routing-links): these links only touch
          # local PipeWire nodes, so they must come up at every boot AND every
          # time the graph is rebuilt (device churn, `dante on/off` bouncing
          # wireplumber, a plain `systemctl --user restart pipewire`). partOf +
          # bindsTo only propagate *stop/restart* — they tear this unit down
          # with pipewire/wireplumber but never start it back up. So this is
          # ALSO wantedBy those two units: each (re)start of pipewire/
          # wireplumber pulls the helper back in (After= orders it last), which
          # re-creates the pw-links the restart just dropped. Without this, any
          # pipewire restart short of a reboot leaves games/voice_chat/system
          # audio silent on the TF until next login. The TF node is pinned
          # non-suspending (see the 80-pro-audio-usb rule) so once wired the
          # links never get dropped under it.
          systemd.user.services.studio-local-links =
            let
              localSinks = [
                "system_audio"
                "games"
                "voice_chat"
              ];
              localPairs = builtins.concatMap (s: [
                {
                  out = "${s}:monitor_1";
                  inp = "${yamahaTF}:playback_1";
                }
                {
                  out = "${s}:monitor_2";
                  inp = "${yamahaTF}:playback_2";
                }
              ]) localSinks;
              pwLink = "${pkgs.pipewire}/bin/pw-link";
              linkCmds = lib.concatMapStringsSep "\n" (p: ''try_link "${p.out}" "${p.inp}"'') localPairs;
              linkScript = pkgs.writeShellScript "studio-local-links" ''
                set -u

                # try_link: ports may not exist yet at boot (loopback sink or
                # the TF node still registering). Retry per pair before giving
                # up; "exists" is success (idempotent re-runs on restart).
                try_link() {
                  local out="$1" inp="$2"
                  for j in $(seq 1 20); do
                    out_msg=$(${pwLink} "$out" "$inp" 2>&1) && return 0
                    case "$out_msg" in
                      *"exists"*|*"link exists"*) return 0 ;;
                    esac
                    sleep 1
                  done
                  echo "studio-local-links: failed after retries: $out -> $inp ($out_msg)" >&2
                  return 1
                }

                ${linkCmds}
                exit 0
              '';
            in
            {
              description = "Wire system_audio/games/voice_chat → Yamaha TF for local monitoring (Dante-independent)";
              after = [
                "pipewire.service"
                "wireplumber.service"
              ];
              wants = [ "pipewire.service" ];
              bindsTo = [
                "pipewire.service"
                "wireplumber.service"
              ];
              partOf = [
                "pipewire.service"
                "wireplumber.service"
              ];
              # wantedBy the graph units (not default.target): a Wants edge from
              # pipewire/wireplumber re-pulls this oneshot on every (re)start,
              # so the links are recreated after a graph rebuild — partOf alone
              # would only have stopped it. default.target start is covered
              # transitively (those units are themselves up by login).
              wantedBy = [
                "pipewire.service"
                "wireplumber.service"
              ];
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
                ExecStart = linkScript;
              };
            };

          systemd.user.services.studio-routing-links =
            let
              sinkLinkPairs = builtins.concatMap (
                s:
                (
                  if (s.feedsInto or null) != null then
                    # Local-only sink: its monitor pours into another sink's
                    # capture input. No Dante TX is wired.
                    [
                      {
                        out = "${s.name}:monitor_1";
                        inp = "${s.feedsInto}:playback_1";
                      }
                      {
                        out = "${s.name}:monitor_2";
                        inp = "${s.feedsInto}:playback_2";
                      }
                    ]
                  else
                    [
                      {
                        out = "${s.name}_to_inferno:output_1";
                        inp = "Inferno sink:playback_${toString s.txL}";
                      }
                      {
                        out = "${s.name}_to_inferno:output_2";
                        inp = "Inferno sink:playback_${toString s.txR}";
                      }
                    ]
                )
                ++ builtins.concatMap (f: [
                  {
                    out = "${s.name}:monitor_1";
                    inp = "${f.node}:${f.portL}";
                  }
                  {
                    out = "${s.name}:monitor_2";
                    inp = "${f.node}:${f.portR}";
                  }
                ]) (s.fanout or [ ])
              ) studioRoutedSinks;
              sourceLinkPairs = builtins.concatMap (s: [
                {
                  out = "Inferno source:capture_${toString s.rxL}";
                  inp = "${s.name}_from_inferno:input_1";
                }
                {
                  out = "Inferno source:capture_${toString s.rxR}";
                  inp = "${s.name}_from_inferno:input_2";
                }
              ]) studioRoutedSources;
              # DAW channel remap: by default daw output N → Inferno TX N,
              # but Reaper's master sits on its first stereo output pair
              # (out 1/2). To make Reaper's master land on the named DAW
              # L/R TX channels (TX 95/96), override entries 1 and 2 to
              # cross-route. Other channels stay 1:1 so per-track Reaper
              # routing to higher channel numbers (3-128) still maps to
              # the equivalent Inferno TX index for Galaxy 32 to subscribe.
              dawChannelMap =
                i:
                let
                  n = i + 1;
                in
                if n == 1 then
                  95
                else if n == 2 then
                  96
                # Free up the original 95/96 slots (used to be OUT95/96)
                # so we don't double-send when DAW L/R also maps here.
                else if n == 95 then
                  1
                else if n == 96 then
                  2
                else
                  n;
              dawLinkPairs = lib.genList (i: {
                out = "daw_to_inferno:output_${toString (i + 1)}";
                inp = "Inferno sink:playback_${toString (dawChannelMap i)}";
              }) 128;
              # daw_inputs: mirror of dawLinkPairs in the capture direction.
              # Reverse the same channel map so that Reaper recording on
              # daw_inputs input 1/2 reads from Inferno RX 95/96, etc.
              dawInputLinkPairs = lib.genList (i: {
                out = "Inferno source:capture_${toString (dawChannelMap i)}";
                inp = "daw_from_inferno:input_${toString (i + 1)}";
              }) 128;
              allPairs = sinkLinkPairs ++ sourceLinkPairs ++ dawLinkPairs ++ dawInputLinkPairs;
              pwLink = "${pkgs.pipewire}/bin/pw-link";
              pwCli = "${pkgs.pipewire}/bin/pw-cli";
              linkCmds = lib.concatMapStringsSep "\n" (p: ''try_link "${p.out}" "${p.inp}"'') allPairs;
              linkScript = pkgs.writeShellScript "studio-routing-links" ''
                set -u

                # Wait for Inferno sink/source to register. The ALSA plugin
                # has to spin up its Dante DeviceServer first, which can
                # take several seconds after pipewire start.
                for i in $(seq 1 60); do
                  if ${pwCli} ls Node 2>/dev/null \
                       | grep -q 'node.name = "Inferno sink"' \
                     && ${pwCli} ls Node 2>/dev/null \
                       | grep -q 'node.name = "Inferno source"' ; then
                    break
                  fi
                  sleep 1
                done

                # try_link: pw-link can fail if either port doesn't exist
                # yet (loopback node not registered, etc). Retry up to 10
                # times per pair before giving up. "exists" is success.
                try_link() {
                  local out="$1" inp="$2"
                  for j in $(seq 1 10); do
                    out_msg=$(${pwLink} "$out" "$inp" 2>&1) && return 0
                    case "$out_msg" in
                      *"exists"*|*"link exists"*) return 0 ;;
                    esac
                    sleep 1
                  done
                  echo "studio-routing-links: failed after retries: $out -> $inp ($out_msg)" >&2
                  return 1
                }

                ${linkCmds}
                exit 0
              '';
            in
            {
              description = "Wire studio loopback nodes to specific Inferno channel pairs";
              after = [
                "pipewire.service"
                "wireplumber.service"
              ];
              wants = [ "pipewire.service" ];
              # bindsTo + partOf means: a restart of these services restarts
              # us, and a stop stops us. Without this, restarting pipewire OR
              # wireplumber (including the studio-clock-ready / watchdog
              # re-init) leaves the studio routing graph un-linked — which
              # surfaces as silent Dante TX (loopback->Inferno links stuck in
              # "init") and Reaper reconnect loops. wireplumber is included
              # because re-initialising the Inferno node is done by bouncing
              # wireplumber, and that drops every pw-link it had made.
              bindsTo = [
                "pipewire.service"
                "wireplumber.service"
              ];
              partOf = [
                "pipewire.service"
                "wireplumber.service"
                # Gated behind dante.target (`dante on|off`): the links pull
                # the Inferno nodes into the active graph, which wedges
                # PipeWire when the Dante network is absent.
                "dante.target"
              ];
              wantedBy = [ "dante.target" ];
              serviceConfig = {
                # simple, NOT oneshot: linkScript can sleep for many minutes
                # when Inferno nodes are missing (60s node wait + 10s of
                # retries per link pair). As oneshot that whole wait lives
                # inside the start job, blocking multi-user.target — which
                # wedges every nixos-rebuild switch (pipewire restart →
                # partOf restarts us → switch waits) and marks the unit
                # failed if interrupted. simple + RemainAfterExit keeps the
                # partOf/bindsTo re-wire semantics (unit stays "active
                # (exited)" after the script finishes) without ever holding
                # a start job open.
                Type = "simple";
                RemainAfterExit = true;
                ExecStart = linkScript;
              };
            };

          # --- Clock-ready re-init ---
          #
          # PipeWire opens the Inferno ALSA node at boot, before statime has
          # locked the Dante PTP clock. Opened against a missing/invalid clock,
          # the node comes up frozen ("init" links, silent TX) and never
          # recovers on its own. So once statime is locked, bounce wireplumber
          # once: the Inferno node re-opens against the valid clock and
          # studio-routing-links (partOf wireplumber) re-wires the channels.
          # This is the one manual step that fixed a total Dante outage,
          # automated.
          # ── PipeWire core watchdog ─────────────────────────────────────
          # pipewire 1.6's link-creation path can deadlock the core's main
          # loop against the data-loop lock during device churn (observed:
          # REAPER's jack_connect during Yamaha TF bring-up → core wedged →
          # REAPER stuck on launch forever). The watchdog probes the core
          # with a short-timeout pw-cli round-trip; two consecutive misses
          # restart the audio stack, which unblocks any client stuck in a
          # jack do_sync (the dead socket errors their call out).
          systemd.user.services.pipewire-watchdog = {
            description = "Restart PipeWire if its core stops answering";
            serviceConfig = {
              Type = "oneshot";
              ExecStart = pkgs.writeShellScript "pipewire-watchdog" ''
                probe() {
                  ${pkgs.coreutils}/bin/timeout 3 \
                    ${pkgs.pipewire}/bin/pw-cli info 0 >/dev/null 2>&1
                }
                if probe; then exit 0; fi
                # One retry to ride out a momentarily busy loop.
                sleep 2
                if probe; then exit 0; fi
                echo "PipeWire core unresponsive; restarting audio stack."
                ${pkgs.systemd}/bin/systemctl --user restart \
                  pipewire.service wireplumber.service pipewire-pulse.service
              '';
            };
          };
          systemd.user.timers.pipewire-watchdog = {
            wantedBy = [ "timers.target" ];
            timerConfig = {
              OnBootSec = "30s";
              OnUnitActiveSec = "10s";
            };
          };

          systemd.user.services.studio-clock-ready = {
            description = "Re-init the audio session once the Dante PTP clock is locked";
            after = [
              "statime-inferno.service"
              "pipewire.service"
              "wireplumber.service"
            ];
            wants = [ "statime-inferno.service" ];
            # Gated behind dante.target — without the Dante network there is
            # no clock to wait for (and the wait would bounce wireplumber).
            partOf = [ "dante.target" ];
            wantedBy = [ "dante.target" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = pkgs.writeShellScript "studio-clock-ready" ''
                jctl=${pkgs.systemd}/bin/journalctl
                sctl=${pkgs.systemd}/bin/systemctl
                # Wait (up to ~2min) until statime is emitting Measurement
                # lines, i.e. locked as a PTP follower.
                for i in $(seq 1 60); do
                  if [ "$("$jctl" --user -u statime-inferno.service --since '8 seconds ago' -o cat | grep -c 'Measurement:')" -gt 0 ]; then
                    break
                  fi
                  sleep 2
                done
                # Re-open the Inferno node against the now-valid clock.
                "$sctl" --user restart wireplumber.service
              '';
            };
          };

          # --- DAW link router ---
          #
          # pipewire-jack 1.6 has no per-client mechanism to redirect the
          # `system:playback_*` alias — `is_port_default()` in
          # pipewire-jack.c only consults the GLOBAL `default.audio.sink`
          # metadata. REAPER (and other JACK DAWs) auto-connect their
          # outputs to whatever 128-channel sink they enumerate first,
          # which in our graph is the ALSA-backed `Inferno sink` and
          # therefore bypasses the `daw` proxy + per-channel renames that
          # daw_to_inferno applies (DAW L/R = TX 95/96, etc).
          #
          # Solution: a tiny rule-driven daemon that watches
          # `pw-mon` for new Link events and rewrites any
          #   <DAW_BINARY>:outN -> Inferno sink:playback_M
          # link into the equivalent
          #   <DAW_BINARY>:outN -> daw:playback_M
          # connection. The match list is declarative — adding Ardour,
          # Bitwig, etc. is one line each. Same rule applies in reverse
          # (input direction) if/when DAWs auto-connect Inferno source.
          systemd.user.services.daw-router =
            let
              dawBinaries = [
                "reaper"
                "ardour"
                "bitwig-studio"
                "Bitwig Studio"
                "harrison-mixbus"
                "qtractor"
                "rosegarden"
                "carla"
              ];
              # DAW isolation policy: a DAW client's only legal peers are
              # the `daw` Audio/Sink (output side) and `daw_inputs`
              # Audio/Source (capture side). ANY other connection — to
              # Inferno sink/source, Yamaha TF capture, webcams, etc. —
              # is treated as an erroneous JACK auto-connect and
              # rewritten/dropped by daw-router.
              dawOutputProxy = "daw";
              dawInputProxy = "daw_inputs";
              dawRouter = pkgs.writeShellScript "daw-router" ''
                set -u
                pwLink=${pkgs.pipewire}/bin/pw-link
                pwMon=${pkgs.pipewire}/bin/pw-mon
                pwDump=${pkgs.pipewire}/bin/pw-dump

                outProxy='${dawOutputProxy}'
                inProxy='${dawInputProxy}'

                # Map node-name -> application.process.binary from pw-dump
                # JSON; pw-cli's text listing omits some props for JACK
                # clients which broke the prior bash-only parser.
                declare -A nodeBin
                refresh_node_binaries() {
                  nodeBin=()
                  while IFS=$'\t' read -r name bin; do
                    [ -n "$name" ] || continue
                    [ -n "$bin" ] || continue
                    nodeBin["$name"]="$bin"
                  done < <(
                    "$pwDump" Node 2>/dev/null \
                      | ${pkgs.jq}/bin/jq -r '
                          .[]
                          | select(.info != null and .info.props != null)
                          | [ .info.props["node.name"] // ""
                            , .info.props["application.process.binary"] // ""
                            ]
                          | @tsv
                        '
                  )
                }

                is_daw_node() {
                  local node="$1"
                  local bin="''${nodeBin[$node]:-}"
                  case "$bin" in
                    ${lib.concatMapStringsSep "|" (b: ''"${b}"'') dawBinaries}) return 0 ;;
                  esac
                  # Fallback: well-known DAW node names. application.process.binary
                  # can be empty for JACK clients launched inside FHS wrappers.
                  case "$node" in
                    REAPER|REAPER[0-9]*|"Bitwig Studio"|Ardour|ardour*|Qtractor|qtractor*) return 0 ;;
                  esac
                  return 1
                }

                # Extract the trailing integer from a port name. Handles
                # both PipeWire-native ("playback_42", "input_7") and
                # JACK-style port names ("out95", "in12") where the
                # number isn't underscore-separated.
                port_index() {
                  local p="$1"
                  # Strip everything up to the last run of digits.
                  echo "$p" | ${pkgs.gnused}/bin/sed -nE 's/^.*[^0-9]([0-9]+)$/\1/p; t; s/^([0-9]+)$/\1/p'
                }

                rewrite_now() {
                  refresh_node_binaries
                  local pairs rewrites=0
                  pairs=$("$pwLink" -lo 2>/dev/null \
                    | ${pkgs.gawk}/bin/awk '
                        /^[^[:space:]]/ { src=$0; next }
                        /-> / {
                          dst=$0; sub(/^[[:space:]]*\|-> /, "", dst);
                          printf "%s\t%s\n", src, dst;
                        }
                      ')
                  while IFS=$'\t' read -r src dst; do
                    [ -n "$src" ] || continue
                    [ -n "$dst" ] || continue
                    local srcNode="''${src%%:*}" srcPort="''${src#*:}"
                    local dstNode="''${dst%%:*}" dstPort="''${dst#*:}"

                    # MIDI links are not audio routing — leave them alone.
                    # The daw/daw_inputs proxies are audio-only loopbacks, so
                    # rewriting a MIDI link onto them always fails and just
                    # disconnects the device (drums -> REAPER:MIDI Input N).
                    case "$srcNode $srcPort $dstPort" in
                      *Midi-Bridge*|*"MIDI Input"*|*"MIDI Output"*|*midi*) continue ;;
                    esac

                    # Output direction: DAW source -> anything other than the
                    # daw proxy. Drop and re-target onto daw:playback_<N>.
                    if is_daw_node "$srcNode" && [ "$dstNode" != "$outProxy" ]; then
                      local n
                      n=$(port_index "$srcPort")
                      "$pwLink" -d "$src" "$dst" >/dev/null 2>&1 || true
                      if [ -n "$n" ] && [ "$n" -eq "$n" ] 2>/dev/null \
                         && "$pwLink" "$src" "$outProxy:playback_$n" >/dev/null 2>&1; then
                        echo "daw-router: OUT $src ->/ $dst => $outProxy:playback_$n" >&2
                      else
                        echo "daw-router: OUT $src ->/ $dst (dropped)" >&2
                      fi
                      rewrites=$((rewrites + 1))
                      continue
                    fi

                    # Input direction: anything other than the daw_inputs
                    # source -> DAW node. Drop and re-target onto
                    # daw_inputs:capture_<N>.
                    if is_daw_node "$dstNode" && [ "$srcNode" != "$inProxy" ]; then
                      local n
                      n=$(port_index "$dstPort")
                      "$pwLink" -d "$src" "$dst" >/dev/null 2>&1 || true
                      if [ -n "$n" ] && [ "$n" -eq "$n" ] 2>/dev/null \
                         && "$pwLink" "$inProxy:capture_$n" "$dst" >/dev/null 2>&1; then
                        echo "daw-router: IN  $src /-> $dst => $inProxy:capture_$n" >&2
                      else
                        echo "daw-router: IN  $src /-> $dst (dropped)" >&2
                      fi
                      rewrites=$((rewrites + 1))
                      continue
                    fi
                  done <<< "$pairs"

                  if [ "$rewrites" -gt 0 ]; then
                    echo "daw-router: $rewrites rewrites this pass" >&2
                  fi
                }

                # Initial pass, then watch for relevant pw-mon events.
                # We only rescan when a *Link* is added/changed/removed,
                # not on every node/port event — pw-mon's event stream is
                # constant chatter from Inferno mDNS / etc and rescanning
                # on every line burns 100% CPU.
                rewrite_now
                last_run=$(date +%s)
                # pw-mon prints multi-line records:
                #   added:
                #   \tid: 123
                #   \ttype: PipeWire:Interface:Link/3
                # We can't easily filter to Link-only events without a
                # full parser, so just fire on every event header — the
                # 3 s debounce below caps the actual rescan rate.
                "$pwMon" 2>/dev/null \
                  | ${pkgs.gawk}/bin/awk '/^(added|changed|removed):/{print; fflush()}' \
                  | while read -r _evt; do
                      now=$(date +%s)
                      # Hard debounce: at most one rescan every 3 seconds.
                      # The libpipewire-jack auto-connect happens in bursts
                      # (REAPER registers 128 ports + connects them in a
                      # few hundred ms), so 3s catches the whole burst with
                      # one rewrite pass.
                      if [ $((now - last_run)) -ge 3 ]; then
                        rewrite_now
                        last_run=$now
                      fi
                    done
              '';
            in
            {
              description = "Rewrite DAW JACK auto-connects from Inferno sink onto the daw proxy";
              after = [ "pipewire.service" ];
              wants = [ "pipewire.service" ];
              bindsTo = [ "pipewire.service" ];
              partOf = [ "pipewire.service" ];
              wantedBy = [ "default.target" ];
              serviceConfig = {
                Type = "simple";
                Restart = "on-failure";
                RestartSec = 2;
                ExecStart = dawRouter;
              };
            };

          # --- Network sniffing / WiFi-hotspot toolkit for Yamaha TF reverse-engineering ---
          # Lets cody capture packets without sudo and stand up an ad-hoc AP so the
          # iPad TF StageMix app can be MITM'd through this host's wifi adapter
          # (wlp14s0u4i2). Wireshark group membership is added to cody above.
          programs.wireshark = {
            enable = true;
            package = pkgs.wireshark;
          };
          # Permissive dumpcap wrapper so the agent shell (started before
          # the wireshark group landed) can capture without re-login.
          security.wrappers.dumpcap-any = {
            source = "${pkgs.wireshark}/bin/dumpcap";
            capabilities = "cap_net_raw,cap_net_admin+eip";
            owner = "root";
            group = "root";
            permissions = "u+rx,g+rx,o+rx";
          };
          environment.systemPackages = with pkgs; [
            iw
            hostapd
            dnsmasq
            tcpdump
            dsniff
            bettercap
            aircrack-ng
            ethtool # I226-V EEE-off recovery + manual debugging

            # ── Realtime-audio diagnostics / tuning ──
            rt-tests # cyclictest — worst-case scheduling jitter
            jack-example-tools # jack_iodelay (round-trip), jack_lsp -L (port latency)
            stress-ng # load generator for cyclictest-under-load
            cpufrequtils # cpupower — inspect / pin CPU frequency
            # rtcqs (realTimeConfigQuickScan) isn't in nixpkgs; thin wrapper runs
            # it from PyPI via uv (downloads on first use, then cached).
            uv
            (writeShellScriptBin "rtcqs" ''exec ${uv}/bin/uvx rtcqs "$@"'')
          ];

          # --- Dante / Inferno audio network configuration ---

          # Disable systemd-timesyncd — it conflicts with statime-inferno PTP daemon
          services.timesyncd.enable = false;

          # Firewall rules for Dante audio network
          networking.firewall = {
            allowedUDPPorts = [
              319
              320
              4400
              4401
              8800
              4402
              4455
              5353
              8700
              8800
            ];
            # Dante allocates ephemeral receive ports dynamically, so we need
            # the full ephemeral range open on the Dante interface (enp12s0).
            # A more precise approach: trust the dedicated Dante interface.
            trustedInterfaces = [
              "enp12s0"
              "wlp14s0u4i2"
            ];
          };
        };
    };
  };
}
