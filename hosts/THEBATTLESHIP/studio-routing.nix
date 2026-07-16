{ den, ... }:
{
  den.aspects.THEBATTLESHIP-studio-routing = {
    description = "Studio PipeWire stack: virtual routing nodes, Dante link oneshots, watchdogs, DAW router";
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
      in
      {
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
                # Inferno's ALSA virtual soundcard (hw_Controller_0) has
                # priority.driver = 2100 by default (same as TF capture),
                # so it wins the PipeWire clock-driver election by node-ID
                # tiebreak. With dante off its clock is invalid — any active
                # audio path produces white noise via the broken SRC.
                # Drop it below TF (2100) so TF always drives the graph clock.
                matches = [
                  { "node.name" = "~alsa_(output|input)\\.hw_Controller_0"; }
                ];
                actions.update-props."priority.driver" = 500;
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
                  # Low-latency device buffer. The device period + headroom is
                  # the fixed latency FLOOR (independent of the graph quantum) —
                  # PipeWire's default 512/512 added ~21 ms/dir. The PREEMPT_RT
                  # kernel's worst-case jitter is ~17 µs (≈1 frame), so a tiny
                  # headroom is safe: 128-frame periods + 32 headroom ≈ 3.3 ms/
                  # dir. period-num stays at the default depth (xrun safety
                  # without adding latency). Raise headroom if USB underruns.
                  "api.alsa.period-size" = 128;
                  "api.alsa.headroom" = 32;
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

            # Graph quantum = the device's default/idle latency. Kept SAFE/high
            # (1024, ~21 ms) so everyday audio (browser/system) stays glitch-free
            # on the shared USB bus. Low latency is requested ON DEMAND per-app:
            # the guitar rig launches with PIPEWIRE_LATENCY=128/48000 (signal's
            # `just rig`), which pulls the interface down to ~2.7 ms only while it
            # runs, then idles back here (min-quantum=32 permits it). mkForce
            # because the audio facet's default pipewire instance also sets this.
            extraConfig.pipewire."92-low-latency".context.properties."default.clock.quantum" = lib.mkForce 1024;

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
      };
  };
}
