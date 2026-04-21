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
      {
        pkgs,
        lib,
        ...
      }:
      {
        security.rtkit.enable = true;

        services.pipewire = {
          enable = true;
          systemWide = true; # Studio: single shared audio daemon for all users

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

        # Default Dante sink/source for the studio workflow
        services.pipewire.wireplumber.extraConfig."51-inferno-default" = {
          "wireplumber.settings" = {
            "default.configured.audio.sink" = "Inferno sink";
            "default.configured.audio.source" = "Inferno source";
          };
        };

        environment.systemPackages = with pkgs; [
          pavucontrol
          alsa-lib
          alsa-tools
          alsa-utils
          alsa-plugins
          crosspipe
          qpwgraph
          qjackctl
          coppwr
        ];

        # System-wide PipeWire needs ALSA_PLUGIN_DIR to find custom plugins (e.g., inferno)
        systemd.services.pipewire.serviceConfig.Environment = [
          "ALSA_PLUGIN_DIR=/run/current-system/sw/lib/alsa-lib"
        ];

        # Add pipewire user to clock group for PTP hardware clock access (Inferno/Dante)
        users.users.pipewire.extraGroups = [ "clock" ];

        # Make system PipeWire socket accessible to audio group members
        # This allows user apps (KDE Plasma, browsers, etc.) to connect to system-wide daemon
        systemd.sockets.pipewire.socketConfig.SocketMode = "0660";
        systemd.sockets.pipewire.socketConfig.SocketGroup = "audio";

        # User service to create symlinks from user runtime dir to system pipewire
        # This allows apps looking in standard location (/run/user/UID) to find system daemon
        systemd.user.services.pipewire-system-bridge = {
          description = "Bridge user PipeWire socket to system daemon";
          wantedBy = [ "default.target" ];
          after = [ "basic.target" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${pkgs.bash}/bin/bash -c 'mkdir -p %t && ln -sf /run/pipewire/pipewire-0 %t/pipewire-0 && ln -sf /run/pipewire/pipewire-0-manager %t/pipewire-0-manager'";
          };
        };

        # Point user apps to system pipewire
        environment.etc."profile.d/pipewire-system.sh".text = ''
          # Use system-wide PipeWire
          export PIPEWIRE_RUNTIME_DIR=/run/pipewire
        '';

        # System-wide PipeWire needs explicit pulse and wireplumber services
        systemd.services.pipewire-pulse = {
          wantedBy = [ "multi-user.target" ];
          serviceConfig.Environment = [
            "PIPEWIRE_RUNTIME_DIR=/run/pipewire"
            "ALSA_PLUGIN_DIR=/run/current-system/sw/lib/alsa-lib"
          ];
        };

        systemd.services.wireplumber = {
          wantedBy = [ "multi-user.target" ];
          serviceConfig.Environment = [
            "PIPEWIRE_RUNTIME_DIR=/run/pipewire"
          ];
        };

        # Make pulse socket accessible to audio group
        systemd.sockets.pipewire-pulse.socketConfig.SocketMode = "0660";
        systemd.sockets.pipewire-pulse.socketConfig.SocketGroup = "audio";

        # User service to bridge PulseAudio socket from user runtime to system
        # The system pulse socket is at /run/pipewire/pulse/native (via %t/pulse/native in service)
        systemd.user.services.pulseaudio-system-bridge = {
          description = "Bridge user PulseAudio socket to system daemon";
          wantedBy = [ "default.target" ];
          after = [ "basic.target" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${pkgs.bash}/bin/bash -c 'mkdir -p %t/pulse && ln -sf /run/pipewire/pulse/native %t/pulse/native'";
          };
        };
      };
  };
}
