# PipeWire audio aspect.
#
# User-session PipeWire so Inferno and desktop apps share the same graph from
# Cody's login session instead of a system-wide daemon.
#
# The module is parametric so it can be deployed on multiple hosts:
#
#   (fleet.hardware._.audio._.pipewire {
#     defaultSink = "system_audio";
#     defaultSource = "talkback_mic";
#     stickyNodes = [
#       "alsa_output.pci-0000_01_00.1.hdmi-stereo-extra1"
#     ];
#   })
#
# When called with no args (the default via the audio facet), you get a plain
# low-latency PipeWire setup. Hosts that need studio routing should configure
# them in their own aspect on top of this.
{ den, ... }:
{
  fleet.hardware._.audio._.pipewire = {
    description = "PipeWire audio system (user-session, low-latency)";

    __functor =
      _self:
      {
        defaultSink ? null,
        defaultSource ? null,
        stickyNodes ? [ ],
        clockRate ? 48000,
        clockQuantum ? 256,
        clockMinQuantum ? 32,
        clockMaxQuantum ? 1024,
        pulseMinReq ? "32/48000",
        pulseDefaultReq ? "256/48000",
        pulseMaxReq ? "1024/48000",
        resampleQuality ? 4,
        ...
      }:
      {
        includes = [
          (
            { host, ... }:
            let
              audioGroups = [
                "audio"
                "pipewire"
              ];
            in
            {
              nixos =
                { lib, ... }:
                {
                  users.users =
                    (lib.listToAttrs (
                      map (userName: {
                        name = userName;
                        value = {
                          extraGroups = audioGroups;
                        };
                      }) (builtins.attrNames host.users)
                    ))
                    // {
                    };
                };
            }
          )
          (
            { host, ... }:
            {
              nixos.users.users = builtins.mapAttrs (_: _: { linger = true; }) host.users;
            }
          )
        ];

        nixos =
          {
            pkgs,
            lib,
            ...
          }:
          {
            security.rtkit.enable = true;

            services.pipewire = {
              enable = true;
              systemWide = false;
              socketActivation = false;

              alsa = {
                enable = true;
                support32Bit = true;
              };
              pulse.enable = true;
              jack.enable = true;
              wireplumber.enable = true;

              extraConfig.pipewire."91-studio-sinks"."context.objects" = [
                {
                  factory = "spa-node-factory";
                  args = {
                    "factory.name" = "support.node.driver";
                    "node.name" = "Dummy-Driver";
                    "priority.driver" = 8000;
                  };
                }
                {
                  factory = "adapter";
                  flags = [ "nofail" ];
                  args = {
                    "factory.name" = "support.null-audio-sink";
                    "node.name" = "system_audio";
                    "node.description" = "System Audio";
                    "media.class" = "Audio/Sink";
                    "audio.position" = [
                      "FL"
                      "FR"
                    ];
                    "priority.session" = 1000;
                    "object.linger" = true;
                  };
                }
                {
                  factory = "adapter";
                  flags = [ "nofail" ];
                  args = {
                    "factory.name" = "support.null-audio-sink";
                    "node.name" = "system_notifications";
                    "node.description" = "System Notifications";
                    "media.class" = "Audio/Sink";
                    "audio.position" = [
                      "FL"
                      "FR"
                    ];
                    "priority.session" = 800;
                    "object.linger" = true;
                    "monitor.channel-volumes" = true;
                    "monitor.passthrough" = true;
                    "adapter.auto-port-config" = {
                      mode = "dsp";
                      monitor = true;
                      position = "preserve";
                    };
                  };
                }
                {
                  factory = "adapter";
                  flags = [ "nofail" ];
                  args = {
                    "factory.name" = "support.null-audio-sink";
                    "node.name" = "voice_chat";
                    "node.description" = "Voice Chat";
                    "media.class" = "Audio/Sink";
                    "audio.position" = [
                      "FL"
                      "FR"
                    ];
                    "priority.session" = 850;
                    "object.linger" = true;
                    "monitor.channel-volumes" = true;
                    "monitor.passthrough" = true;
                    "adapter.auto-port-config" = {
                      mode = "dsp";
                      monitor = true;
                      position = "preserve";
                    };
                  };
                }
                {
                  factory = "adapter";
                  flags = [ "nofail" ];
                  args = {
                    "factory.name" = "support.null-audio-sink";
                    "node.name" = "games";
                    "node.description" = "Games";
                    "media.class" = "Audio/Sink";
                    "audio.position" = [
                      "FL"
                      "FR"
                    ];
                    "priority.session" = 900;
                    "object.linger" = true;
                  };
                }
                {
                  factory = "adapter";
                  flags = [ "nofail" ];
                  args = {
                    "factory.name" = "support.null-audio-sink";
                    "node.name" = "daw";
                    "node.description" = "DAW";
                    "media.class" = "Audio/Sink";
                    "audio.channels" = 128;
                    "audio.position" = lib.genList (i: "AUX${toString i}") 128;
                    "adapter.auto-port-config" = {
                      mode = "dsp";
                      monitor = true;
                      position = "preserve";
                    };
                    "priority.session" = 950;
                    "object.linger" = true;
                    "monitor.channel-volumes" = true;
                    "monitor.passthrough" = true;
                  };
                }
                {
                  factory = "adapter";
                  flags = [ "nofail" ];
                  args = {
                    "factory.name" = "support.null-audio-sink";
                    "node.name" = "daw_broadcast";
                    "node.description" = "DAW Broadcast";
                    "media.class" = "Audio/Source/Virtual";
                    "audio.position" = [
                      "FL"
                      "FR"
                    ];
                    "priority.session" = 900;
                    "object.linger" = true;
                    "monitor.channel-volumes" = true;
                    "monitor.passthrough" = true;
                    "adapter.auto-port-config" = {
                      mode = "dsp";
                      monitor = true;
                      position = "preserve";
                    };
                  };
                }
                {
                  factory = "adapter";
                  flags = [ "nofail" ];
                  args = {
                    "factory.name" = "support.null-audio-sink";
                    "node.name" = "talkback_mic";
                    "node.description" = "Talkback Mic";
                    "media.class" = "Audio/Source/Virtual";
                    "audio.position" = [ "MONO" ];
                    "priority.session" = 1000;
                    "object.linger" = true;
                    "monitor.channel-volumes" = true;
                    "monitor.passthrough" = true;
                    "adapter.auto-port-config" = {
                      mode = "dsp";
                      monitor = true;
                      position = "preserve";
                    };
                  };
                }
                {
                  factory = "adapter";
                  flags = [ "nofail" ];
                  args = {
                    "factory.name" = "support.null-audio-sink";
                    "node.name" = "talkback_mic_dsp";
                    "node.description" = "Talkback Mic [DSP]";
                    "media.class" = "Audio/Source/Virtual";
                    "audio.position" = [ "MONO" ];
                    "priority.session" = 999;
                    "object.linger" = true;
                  };
                }
              ];

              extraConfig.pipewire."92-low-latency".context.properties = {
                "default.clock.rate" = clockRate;
                "default.clock.quantum" = clockQuantum;
                "default.clock.min-quantum" = clockMinQuantum;
                "default.clock.max-quantum" = clockMaxQuantum;
              };

              extraConfig.pipewire-pulse."92-low-latency" = {
                "pulse.properties" = {
                  "pulse.min.req" = pulseMinReq;
                  "pulse.default.req" = pulseDefaultReq;
                  "pulse.max.req" = pulseMaxReq;
                  "pulse.min.quantum" = pulseMinReq;
                  "pulse.max.quantum" = pulseMaxReq;
                };
                "stream.properties" = {
                  "node.latency" = pulseDefaultReq;
                  "resample.quality" = resampleQuality;
                };
              };

              wireplumber.extraConfig =
                lib.optionalAttrs (defaultSink != null || defaultSource != null) {
                  "10-defaults".wireplumber.settings = lib.filterAttrs (_: v: v != null) {
                    "default.configured.audio.sink" = defaultSink;
                    "default.configured.audio.source" = defaultSource;
                  };
                }
                // lib.optionalAttrs (stickyNodes != [ ]) {
                  "99-disable-suspend"."monitor.alsa.rules" = [
                    {
                      matches = map (name: { "node.name" = name; }) stickyNodes;
                      actions.update-props = {
                        "session.suspend-timeout-seconds" = 0;
                        "node.always-process" = true;
                        "dither.method" = "wannamaker3";
                        "dither.noise" = 1;
                      };
                    }
                  ];
                };
            };

            systemd.user.services.pipewire.serviceConfig = {
              Environment = [ "ALSA_PLUGIN_DIR=/run/current-system/sw/lib/alsa-lib" ];
              SystemCallFilter = [
                "@system-service"
                "@clock"
              ];
            };

            environment.systemPackages = with pkgs; [
              pavucontrol
              pwvucontrol
              qpwgraph
              qjackctl
              coppwr
              crosspipe
              alsa-utils
            ];
          };
      };
  };
}
