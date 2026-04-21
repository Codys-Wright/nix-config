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

          # Human-friendly studio buses. These are named virtual sinks/sources
          # that we can target from WirePlumber/Pulse rules instead of routing
          # apps directly to the raw Dante device.
          extraConfig.pipewire."94-studio-buses" = {
            context.modules = [
              {
                name = "libpipewire-module-loopback";
                args = {
                  node.description = "Broadcast";
                  capture.props = {
                    node.name = "broadcast";
                    media.class = "Audio/Sink";
                    audio.position = [
                      "FL"
                      "FR"
                    ];
                    priority.session = 500;
                  };
                  playback.props = {
                    node.name = "broadcast.playback";
                    target.object = "Inferno sink";
                    node.passive = true;
                    node.dont-reconnect = true;
                    stream.dont-remix = true;
                    audio.position = [
                      "FL"
                      "FR"
                    ];
                  };
                };
              }
              {
                name = "libpipewire-module-loopback";
                args = {
                  node.description = "System Audio";
                  capture.props = {
                    node.name = "system_audio";
                    media.class = "Audio/Sink";
                    audio.position = [
                      "FL"
                      "FR"
                    ];
                    priority.session = 1000;
                  };
                  playback.props = {
                    node.name = "system-audio.playback";
                    target.object = "broadcast";
                    node.passive = true;
                    node.dont-reconnect = true;
                    stream.dont-remix = true;
                    audio.position = [
                      "FL"
                      "FR"
                    ];
                  };
                };
              }
              {
                name = "libpipewire-module-loopback";
                args = {
                  node.description = "System Notifications";
                  capture.props = {
                    node.name = "system_notifications";
                    media.class = "Audio/Sink";
                    audio.position = [
                      "FL"
                      "FR"
                    ];
                    priority.session = 800;
                  };
                  playback.props = {
                    node.name = "system-notifications.playback";
                    target.object = "system_audio";
                    node.passive = true;
                    node.dont-reconnect = true;
                    stream.dont-remix = true;
                    audio.position = [
                      "FL"
                      "FR"
                    ];
                  };
                };
              }
              {
                name = "libpipewire-module-loopback";
                args = {
                  node.description = "Voice Chat";
                  capture.props = {
                    node.name = "voice_chat";
                    media.class = "Audio/Sink";
                    audio.position = [
                      "FL"
                      "FR"
                    ];
                    priority.session = 850;
                  };
                  playback.props = {
                    node.name = "voice-chat.playback";
                    target.object = "broadcast";
                    node.passive = true;
                    node.dont-reconnect = true;
                    stream.dont-remix = true;
                    audio.position = [
                      "FL"
                      "FR"
                    ];
                  };
                };
              }
              {
                name = "libpipewire-module-loopback";
                args = {
                  node.description = "Daw";
                  capture.props = {
                    node.name = "daw";
                    media.class = "Audio/Sink";
                    audio.channels = 16;
                    audio.position = [
                      "FL"
                      "FR"
                      "RL"
                      "RR"
                      "FC"
                      "LFE"
                      "SL"
                      "SR"
                      "AUX0"
                      "AUX1"
                      "AUX2"
                      "AUX3"
                      "AUX4"
                      "AUX5"
                      "AUX6"
                      "AUX7"
                    ];
                    priority.session = 950;
                  };
                  playback.props = {
                    node.name = "daw.playback";
                    target.object = "Inferno sink";
                    node.passive = true;
                    node.dont-reconnect = true;
                    stream.dont-remix = true;
                    audio.position = [
                      "FL"
                      "FR"
                      "RL"
                      "RR"
                      "FC"
                      "LFE"
                      "SL"
                      "SR"
                      "AUX0"
                      "AUX1"
                      "AUX2"
                      "AUX3"
                      "AUX4"
                      "AUX5"
                      "AUX6"
                      "AUX7"
                    ];
                  };
                };
              }
              {
                name = "libpipewire-module-loopback";
                args = {
                  node.description = "Daw Broadcast";
                  capture.props = {
                    node.name = "daw_broadcast.capture";
                    target.object = "daw";
                    stream.capture.sink = true;
                    node.passive = true;
                    node.dont-reconnect = true;
                    stream.dont-remix = true;
                  };
                  playback.props = {
                    node.name = "daw_broadcast";
                    media.class = "Audio/Source";
                    audio.position = [
                      "FL"
                      "FR"
                    ];
                    priority.session = 900;
                  };
                };
              }
              {
                name = "libpipewire-module-loopback";
                args = {
                  node.description = "Talkback Mic";
                  capture.props = {
                    # Leave the capture side untargeted so WirePlumber can bind
                    # this source to the best available physical microphone.
                    node.name = "talkback_mic.capture";
                    node.passive = true;
                    node.dont-reconnect = true;
                    stream.dont-remix = true;
                    audio.position = [ "MONO" ];
                  };
                  playback.props = {
                    node.name = "talkback_mic";
                    media.class = "Audio/Source";
                    audio.position = [ "MONO" ];
                    priority.session = 1000;
                  };
                };
              }
            ];
          };
        };

        # Default studio buses for the workflow.
        services.pipewire.wireplumber.extraConfig."51-studio-defaults" = {
          "wireplumber.settings" = {
            "default.configured.audio.sink" = "system_audio";
            "default.configured.audio.source" = "talkback_mic";
          };
        };

        # Route common applications to the named buses above.
        services.pipewire.extraConfig.pipewire-pulse."93-studio-routing" = {
          stream.rules = [
            {
              matches = [
                {
                  application.name = "Brave Browser";
                }
                {
                  application.name = "Firefox";
                }
                {
                  application.name = "Chromium";
                }
                {
                  application.name = "Google Chrome";
                }
                {
                  application.name = "Zen Browser";
                }
              ];
              actions = {
                update-props = {
                  target.object = "system_audio";
                };
              };
            }
            {
              matches = [
                {
                  application.name = "Discord";
                }
                {
                  application.name = "Discord Canary";
                }
                {
                  application.name = "Vesktop";
                }
                {
                  application.name = "WebCord";
                }
                {
                  application.name = "Microsoft Teams";
                }
                {
                  application.name = "Teams for Linux";
                }
              ];
              actions = {
                update-props = {
                  target.object = "voice_chat";
                };
              };
            }
            {
              matches = [
                {
                  application.name = "REAPER";
                }
                {
                  application.name = "Reaper";
                }
                {
                  application.name = "reaper";
                }
              ];
              actions = {
                update-props = {
                  target.object = "daw";
                };
              };
            }
            {
              matches = [
                {
                  application.name = "OBS Studio";
                }
                {
                  application.name = "OBS";
                }
              ];
              actions = {
                update-props = {
                  target.object = "broadcast";
                };
              };
            }
            {
              matches = [
                {
                  media.role = "event";
                }
              ];
              actions = {
                update-props = {
                  target.object = "system_notifications";
                };
              };
            }
            {
              matches = [
                {
                  application.process.binary = "reaper";
                }
                {
                  application.process.binary = "reaper.exe";
                }
              ];
              actions = {
                update-props = {
                  target.object = "daw";
                };
              };
            }
            {
              matches = [
                {
                  application.process.binary = "discord";
                }
                {
                  application.process.binary = "Discord";
                }
                {
                  application.process.binary = "discord-canary";
                }
                {
                  application.process.binary = "vesktop";
                }
                {
                  application.process.binary = "WebCord";
                }
                {
                  application.process.binary = "teams";
                }
                {
                  application.process.binary = "teams-for-linux";
                }
              ];
              actions = {
                update-props = {
                  target.object = "voice_chat";
                };
              };
            }
            {
              matches = [
                {
                  application.process.binary = "obs";
                }
                {
                  application.process.binary = "obs64";
                }
                {
                  application.process.binary = "com.obsproject.Studio";
                }
              ];
              actions = {
                update-props = {
                  target.object = "broadcast";
                };
              };
            }
            {
              matches = [
                {
                  application.process.binary = "brave-browser";
                }
                {
                  application.process.binary = "firefox";
                }
                {
                  application.process.binary = "chromium";
                }
                {
                  application.process.binary = "google-chrome";
                }
                {
                  application.process.binary = "zen-browser";
                }
              ];
              actions = {
                update-props = {
                  target.object = "system_audio";
                };
              };
            }
          ];
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
