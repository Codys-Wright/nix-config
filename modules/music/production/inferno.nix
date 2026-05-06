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
                  infernoPkg = pkgs.callPackage ../../../packages/inferno/inferno.nix { };
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
                  environment.systemPackages = [ infernoPkg ];

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

                  services.pipewire.extraConfig.pipewire."91-inferno" = {
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
                          "session.suspend-timeout-seconds" = 0;
                          "node.pause-on-idle" = false;
                          "node.suspend-on-idle" = false;
                          "node.always-process" = true;
                          "object.linger" = true;
                        };
                      }
                    ];
                  };
                };
            }
          )
        ];
      };
  };
}
