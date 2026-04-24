# Inferno Dante virtual soundcard (ALSA + PipeWire).
#
# Parametric aspect — deploy on any host by calling with the Dante network
# parameters. The host's name is used as the Dante device name, so each host
# shows up in Dante Controller with its own identity.
#
#   (fleet.music._.production._.inferno {
#     bindIp   = "10.10.10.10";   # IP on the Dante interface
#     deviceId = "00000A0A0A0A0001";
#     channels = 128;             # RX/TX channel count
#   })
#
# Design notes:
# * The ALSA PCM plugin is declared in /etc/asound.conf.
# * PipeWire creates the sink/source adapter nodes declaratively via
#   context.objects — no pw-cli scripts, no oneshot services, no cleanup.
# * Nodes are set to never suspend so the Dante stream stays alive on the
#   network (otherwise Inferno stops emulating the device when nothing reads
#   or writes, which takes several seconds to recover from).
# * Requires system-wide PipeWire (see fleet.hardware._.audio._.pipewire) so
#   the plugin is loaded at boot before any user logs in.
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
        latencyNs ? 1000000, # 1ms
        pcmName ? "inferno",
        processId ? "1",
        altPort ? "4400",
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
                in
                {
                  environment.systemPackages = [ infernoPkg ];

                  # Let ALSA find the Inferno PCM plugin shipped by the inferno
                  # package.
                  environment.pathsToLink = [ "/lib/alsa-lib" ];
                  environment.variables.ALSA_PLUGIN_DIR = "/run/current-system/sw/lib/alsa-lib";

                  # Declare the virtual Dante soundcard. NAME is the host's
                  # name so Dante Controller shows each machine with its own
                  # identity.
                  environment.etc."asound.conf".text = ''
                    pcm!default { type null }
                    ctl!default { type null }

                    pcm.${pcmName} {
                      type inferno
                      NAME "${host.name}"
                      DEVICE_ID "${deviceId}"
                      BIND_IP "${bindIp}"
                      PROCESS_ID "${processId}"
                      ALT_PORT "${altPort}"
                      SAMPLE_RATE "${toString sampleRate}"
                      RX_CHANNELS "${toString channels}"
                      TX_CHANNELS "${toString channels}"
                      RX_LATENCY_NS "${toString latencyNs}"
                      TX_LATENCY_NS "${toString latencyNs}"

                      hint {
                        show on
                        description "${host.name} Inferno virtual device"
                      }
                    }
                  '';

                  # Declarative PipeWire nodes — created automatically at
                  # pipewire startup, no shell scripts needed. PipeWire probes
                  # the ALSA device for channel count and layout so we don't
                  # set audio.channels / audio.position here.
                  services.pipewire.extraConfig.pipewire."91-inferno" = {
                    "context.objects" = [
                      {
                        factory = "adapter";
                        args = {
                          "factory.name" = "api.alsa.pcm.sink";
                          "node.name" = "Inferno sink";
                          "node.description" = "Inferno Dante Sink";
                          "media.class" = "Audio/Sink";
                          "api.alsa.path" = pcmName;
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
                          "api.alsa.path" = pcmName;
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
