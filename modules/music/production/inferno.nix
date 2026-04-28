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
        ...
      }:
      {
        includes = [
          (
            { host, ... }:
            {
              nixos =
                { pkgs, ... }:
                let
                  infernoPkg = pkgs.callPackage ../../../packages/inferno/inferno.nix { };
                  pcmSink = "inferno_sink";
                  pcmSource = "inferno_source";
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
                      ALT_PORT "4400"
                      SAMPLE_RATE "${toString sampleRate}"
                      RX_CHANNELS "${toString channels}"
                      TX_CHANNELS "${toString channels}"
                      TX_LATENCY_NS "${toString latencyNs}"
                      RX_LATENCY_NS "${toString latencyNs}"

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
                      ALT_PORT "4410"
                      SAMPLE_RATE "${toString sampleRate}"
                      RX_CHANNELS "${toString channels}"
                      TX_CHANNELS "${toString channels}"
                      TX_LATENCY_NS "${toString latencyNs}"
                      RX_LATENCY_NS "${toString latencyNs}"

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
