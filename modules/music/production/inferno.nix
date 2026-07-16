# Inferno Dante virtual soundcard (ALSA + PipeWire).
#
# Parametric aspect — deploy on any host by calling with the Dante network
# parameters. The host's name is used as the Dante device name, so each host
# shows up in Dante Controller with its own identity.
#
#   (fleet.music._.production._.inferno {
#     bindIp   = "10.10.10.10";
#     deviceId = "00000A0A0A0A0001";
#     channels = 128;
#   })
#
# The Inferno ALSA plugin shares a DeviceServer singleton per DEVICE_ID within
# a process. Both the sink (playback) and source (capture) PCM devices use the
# SAME DEVICE_ID so they share a single Dante device on the network — appearing
# as one device with both TX and RX channels in Dante Controller.
#
# The DeviceServer is created by whichever PCM opens first. Both PCMs must
# therefore declare the full channel counts (TX and RX) so the DeviceServer is
# initialised correctly regardless of open order. PROCESS_ID and ALT_PORT
# distinguish the two streams within the shared DeviceServer.
#
# Requires system-wide PipeWire (see fleet.hardware._.audio._.pipewire).
{ fleet, lib, ... }:
{
  fleet.music._.production._.inferno = {
    description = "Inferno Dante virtual soundcard (ALSA + PipeWire)";

    __functor =
      _self:
      {
        bindIp,
        deviceId,
        channels ? 128,
        sampleRate ? 48000,
        latencyNs ? 1000000,
        headroom ? 128,
        card ? 999,
        # Declarative channel-name defaults. Either an attrset
        # `{ "1" = "Master Bus L"; "91" = "Snare"; }` or a list of
        # strings indexed from channel 1. Channels without an entry
        # keep the default `TX N` / `RX N` placeholder.
        # Consumed by inferno_aoip's `TX_CHANNEL_NAMES` /
        # `RX_CHANNEL_NAMES` config keys (see fts/main).
        txChannelNames ? { },
        rxChannelNames ? { },
        ...
      }:
      {
        includes = [
          (
            { host, ... }:
            {
              nixos =
                { pkgs, lib, ... }:
                let
                  infernoPkg = pkgs.fleet-inferno;
                  pcmSink = "inferno_sink";
                  pcmSource = "inferno_source";
                  # Plain numeric channel layout. UNK on every slot makes
                  # PipeWire emit ports named playback_1..N / capture_1..N
                  # instead of FL/FR/AUX… — better for raw multichannel
                  # routing where positions are meaningless and we wire
                  # specific channel pairs with pw-link.
                  positions = lib.replicate channels "UNK";

                  # Serialize a channel-names map (attrset of `id → name`,
                  # or a list of names indexed from 1) into the
                  # `id=name;id=name;…` format inferno_aoip expects.
                  # Names containing `;` would break the parser; reject
                  # them at eval time so the error surfaces here, not at
                  # device runtime.
                  formatChannelNames =
                    src:
                    let
                      asAttrs =
                        if builtins.isList src then
                          lib.listToAttrs (
                            lib.imap1 (i: name: {
                              name = toString i;
                              value = name;
                            }) src
                          )
                        else
                          src;
                      pairs = lib.attrsToList asAttrs;
                      check =
                        p:
                        if lib.hasInfix ";" p.value then
                          throw "inferno: channel name for ${p.name} contains ';' which is the entry separator: ${p.value}"
                        else
                          "${p.name}=${p.value}";
                    in
                    lib.concatMapStringsSep ";" check pairs;

                  txNamesStr = formatChannelNames txChannelNames;
                  rxNamesStr = formatChannelNames rxChannelNames;
                  txNamesLine = if txNamesStr == "" then "" else ''TX_CHANNEL_NAMES "${txNamesStr}"'';
                  rxNamesLine = if rxNamesStr == "" then "" else ''RX_CHANNEL_NAMES "${rxNamesStr}"'';
                in
                {
                  environment.systemPackages = [
                    infernoPkg
                    # Toggle the whole Dante/AoIP stack: `dante on|off|status`.
                    (pkgs.writeShellScriptBin "dante" ''
                      set -e
                      cmd="''${1:-status}"
                      # The whole Dante stack is now per-user (statime gets the
                      # PTP port-bind cap via a setcap wrapper), so everything
                      # rides the user manager — no sudo, no system units.
                      case "$cmd" in
                        on)
                          systemctl --user start dante.target
                          echo "Dante stack starting (PTP clock, Inferno nodes, routing links)."
                          ;;
                        off)
                          systemctl --user stop dante.target
                          echo "Dante stack stopped."
                          ;;
                        status)
                          systemctl --user --no-pager list-units --all \
                            'dante.target' 'inferno-nodes.service' 'statime-inferno.service' \
                            'dante-preferred-leader.*' 'statime-watchdog.*' 'studio-routing-links.service'
                          ;;
                        *)
                          echo "usage: dante on|off|status" >&2
                          exit 2
                          ;;
                      esac
                    '')
                  ];

                  # (Removed the old "hold system PipeWire until network-online"
                  # hack: PipeWire is now per-user and Inferno's mDNS bind only
                  # happens at `dante on`, which the user runs well after login
                  # when the Dante static IP has long been up.)

                  environment.pathsToLink = [ "/lib/alsa-lib" ];
                  environment.variables.ALSA_PLUGIN_DIR = "/run/current-system/sw/lib/alsa-lib";

                  # Both PCMs share the same DEVICE_ID → same DeviceServer → single
                  # Dante device on the network with TX=channels and RX=channels.
                  # Both declare the full TX+RX counts so the DeviceServer is correct
                  # regardless of which PCM PipeWire opens first.
                  # PROCESS_ID and ALT_PORT distinguish the two streams.
                  environment.etc."asound.conf".text = ''
                    pcm.${pcmSink} {
                      type inferno
                      NAME "${host.name}"
                      DEVICE_ID "${deviceId}"
                      BIND_IP "${bindIp}"
                      PROCESS_ID "1"
                      # ARC port intentionally left at the inferno_aoip default
                      # (4440 — the standard Dante ARC port) so controllers
                      # discover this device alongside hardware Dante endpoints.
                      # Both PCMs share one DeviceServer per DEVICE_ID, so only
                      # one ARC socket is bound regardless of open order.
                      SAMPLE_RATE "${toString sampleRate}"
                      RX_CHANNELS "${toString channels}"
                      TX_CHANNELS "${toString channels}"
                      TX_LATENCY_NS "${toString latencyNs}"
                      RX_LATENCY_NS "${toString latencyNs}"
                      ${txNamesLine}
                      ${rxNamesLine}

                      hint {
                        show on
                        description "${host.name} Inferno playback"
                      }
                    }

                    pcm.${pcmSource} {
                      type inferno
                      NAME "${host.name}"
                      DEVICE_ID "${deviceId}"
                      BIND_IP "${bindIp}"
                      PROCESS_ID "2"
                      # See sink PCM above — no ALT_PORT, share the default
                      # 4440 ARC socket from the singleton DeviceServer.
                      SAMPLE_RATE "${toString sampleRate}"
                      RX_CHANNELS "${toString channels}"
                      TX_CHANNELS "${toString channels}"
                      TX_LATENCY_NS "${toString latencyNs}"
                      RX_LATENCY_NS "${toString latencyNs}"
                      ${txNamesLine}
                      ${rxNamesLine}

                      hint {
                        show on
                        description "${host.name} Inferno capture"
                      }
                    }
                  '';

                  # ── Dante runtime gating ──────────────────────────────────
                  # The Inferno nodes used to live in PipeWire's *static*
                  # config (91-inferno), so the ALSA plugin's DeviceServer
                  # spun up at every PipeWire start. With the Dante network
                  # absent (gear off) the clockless PCM wedges PipeWire's
                  # main loop — JACK clients (REAPER) then block 40-90s per
                  # sync call or hang outright. The nodes now live in a
                  # standalone PipeWire *client* process gated behind
                  # dante.target: `dante on` / `dante off` brings the whole
                  # AoIP stack (PTP clock, soundcard nodes, routing links)
                  # up or down without touching the core audio graph.
                  systemd.user.targets.dante = {
                    description = "Dante/Inferno AoIP stack (PTP clock, virtual soundcard, routing)";
                    # Intentionally not wantedBy default.target: bring it up
                    # explicitly with `dante on` when the network is live.
                  };

                  systemd.user.services.inferno-nodes =
                    let
                      # Store-path conf handed straight to `pipewire -c` (NixOS
                      # disallows raw environment.etc."pipewire/…" entries).
                      infernoNodesConf = pkgs.writeText "inferno-nodes.conf" (
                        builtins.toJSON {
                          "context.properties" = {
                            "log.level" = 2;
                          };
                          "context.spa-libs" = {
                            "audio.convert.*" = "audioconvert/libspa-audioconvert";
                            "api.alsa.*" = "alsa/libspa-alsa";
                            "support.*" = "support/libspa-support";
                          };
                          "context.modules" = [
                            {
                              name = "libpipewire-module-rt";
                              flags = [
                                "ifexists"
                                "nofail"
                              ];
                            }
                            { name = "libpipewire-module-protocol-native"; }
                            { name = "libpipewire-module-client-node"; }
                            { name = "libpipewire-module-adapter"; }
                            { name = "libpipewire-module-metadata"; }
                          ];
                          "context.objects" = [
                            {
                              factory = "adapter";
                              args = {
                                "factory.name" = "api.alsa.pcm.sink";
                                "node.name" = "Inferno sink";
                                "node.description" = "Inferno Dante Sink";
                                "media.class" = "Audio/Sink";
                                "api.alsa.path" = pcmSink;
                                "api.alsa.pcm.card" = toString card;
                                "api.alsa.headroom" = toString headroom;
                                "audio.channels" = channels;
                                "audio.position" = positions;
                                "priority.session" = 2000;
                                "session.suspend-timeout-seconds" = 0;
                                "node.pause-on-idle" = false;
                                "node.suspend-on-idle" = false;
                                "node.always-process" = true;
                                "object.linger" = true;
                                # Hide Inferno from JACK clients — Reaper / other
                                # JACK apps should always route through a higher-
                                # level proxy sink (the host's `daw` 128-ch
                                # loopback) so per-host channel routing rules
                                # apply. Without this, libpipewire-jack auto-
                                # connects every JACK output port to Inferno
                                # sink's playback_N directly, bypassing the
                                # daw_to_inferno indirection.
                                "jack.show" = false;
                              };
                            }
                            {
                              factory = "adapter";
                              args = {
                                "factory.name" = "api.alsa.pcm.source";
                                "node.name" = "Inferno source";
                                "node.description" = "Inferno Dante Source";
                                "media.class" = "Audio/Source";
                                "api.alsa.path" = pcmSource;
                                "api.alsa.pcm.card" = toString card;
                                "api.alsa.headroom" = toString headroom;
                                "audio.channels" = channels;
                                "audio.position" = positions;
                                "priority.session" = 1900;
                                "jack.show" = false;
                                "session.suspend-timeout-seconds" = 0;
                                "node.pause-on-idle" = false;
                                "node.suspend-on-idle" = false;
                                "node.always-process" = true;
                                "object.linger" = true;
                              };
                            }
                          ];
                        }
                      );
                    in
                    {
                      description = "Inferno Dante virtual soundcard nodes (PipeWire client)";
                      # User unit now: order against the user pipewire.service,
                      # no system network-online (Dante IP is up long before
                      # `dante on`). Runs as the logged-in user against the
                      # per-user $XDG_RUNTIME_DIR socket.
                      after = [ "pipewire.service" ];
                      wants = [ "pipewire.service" ];
                      partOf = [ "dante.target" ];
                      wantedBy = [ "dante.target" ];
                      environment = {
                        ALSA_PLUGIN_DIR = "/run/current-system/sw/lib/alsa-lib";
                      };
                      serviceConfig = {
                        Type = "simple";
                        ExecStart = "${pkgs.pipewire}/bin/pipewire -c ${infernoNodesConf}";
                        Restart = "on-failure";
                        RestartSec = "3s";
                      };
                    };
                };
            }
          )
        ];
      };
  };
}
