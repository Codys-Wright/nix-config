# PipeWire audio sub-aspect (can be included independently)
{
  fleet,
  den,
  ...
}:
{
  fleet.hardware._.audio._.pipewire = {
    description = "PipeWire audio system with low-latency configuration";

    includes = [ (den.lib.groups [ "audio" ]) ];

    nixos =
      { pkgs, lib, ... }:
      {
        security.rtkit.enable = true;

        services.pipewire = {
          enable = true;

          alsa = {
            enable = true;
            support32Bit = true;
          };

          jack.enable = true;
          pulse.enable = true;
          wireplumber.enable = true;

          # Flexible latency configuration
          extraConfig.pipewire."92-low-latency" = {
            "context.properties" = {
              "default.clock.rate" = 48000;
              "default.clock.quantum" = 256; # Default buffer (5.3ms)
              "default.clock.min-quantum" = 32; # Can go low for pro audio
              "default.clock.max-quantum" = 1024; # Can go high for stability
            };
          };

          # Virtual stereo sink for PulseAudio clients (Wine/Proton)
          # The Yamaha TF runs in pro-audio mode (raw AUX channels), which
          # Wine's winepulse.drv cannot see. This loopback creates a normal
          # stereo sink that PulseAudio clients can target, and routes audio
          # to the Yamaha's first two pro-audio channels (AUX0/AUX1).
          extraConfig.pipewire."93-yamaha-stereo-sink" = {
            "context.modules" = [
              {
                name = "libpipewire-module-loopback";
                args = {
                  "node.description" = "Yamaha TF Stereo";
                  "node.name" = "yamaha_tf_stereo";
                  "capture.props" = {
                    "media.class" = "Audio/Sink";
                    "audio.position" = "FL,FR";
                  };
                  "playback.props" = {
                    # Link the loopback playback stream to the actual TF pro-audio output node.
                    "target.object" = "alsa_output.usb-Yamaha_Corporation_Yamaha_TF-00.pro-output-0";
                    "audio.position" = "AUX0,AUX1";
                    "node.passive" = true;
                  };
                };
              }
            ];
          };

          # PulseAudio backend configuration with flexible latency
          extraConfig.pipewire-pulse."92-low-latency" = {
            context.modules = [
              {
                name = "libpipewire-module-protocol-pulse";
                args = {
                  pulse.min.req = "32/48000";
                  pulse.default.req = "256/48000";
                  pulse.max.req = "1024/48000";
                  pulse.min.quantum = "32/48000";
                  pulse.max.quantum = "1024/48000";
                };
              }
            ];
            stream.properties = {
              node.latency = "256/48000";
              resample.quality = 4;
            };
          };
        };

        # Make the Yamaha TF Stereo loopback the default sink so
        # PulseAudio clients (Wine/Proton) always have a stable stereo target
        services.pipewire.wireplumber.extraConfig."51-yamaha-default" = {
          "wireplumber.settings" = {
            # The capture side already sets node.name, so the sink node is just `yamaha_tf_stereo`.
            "default.configured.audio.sink" = "yamaha_tf_stereo";
          };
        };

        # Make THEBATTLESHIP Inferno the default for Dante audio workflow
        services.pipewire.wireplumber.extraConfig."52-inferno-default" = {
          "wireplumber.settings" = {
            "default.configured.audio.sink" = "Inferno sink";
            "default.configured.audio.source" = "Inferno source";
          };
        };

        environment.systemPackages = with pkgs; [
          pavucontrol
          crosspipe
          qpwgraph
          qjackctl
          coppwr
        ];
      };
  };
}
