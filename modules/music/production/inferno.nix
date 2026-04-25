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
# The Inferno ALSA plugin emulates both playback and capture from one ALSA
# soundcard. PipeWire should expose that single Inferno PCM to both a sink and
# a source node, matching the upstream PipeWire example.
#
# Requires a user-session PipeWire stack (see fleet.hardware._.audio._.pipewire).
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
            let
              rxChannelNames = [
                "1 - Kick In"
                "2 - Kick Out"
                "3 - Snare Top"
                "4 - Snare Bottom"
                "5 - Tom 1"
                "6 - Tom 2"
                "7 - Tom 3"
                "8 - Tom 4"
                "9 - Hi-Hat"
                "10 - Ride"
                "11 - OH L"
                "12 - OH R"
                "13 - Room L"
                "14 - Room R"
                "15 - Room Far L"
                "16 - Room Far R"
                "17 - Electronic Kit L"
                "18 - Electronic Kit R"
                "19 - Drum Pad L"
                "20 - Drum Pad R"
                "21 - Bass DI"
                "22 - Bass Amp"
                "23 - Bass Synth L"
                "24 - Bass Synth R"
                "25 - Guitar 1 L"
                "26 - Guitar 1 R"
                "27 - Guitar 2 L"
                "28 - Guitar 2 R"
                "29 - Guitar 3 L"
                "30 - Guitar 3 R"
                "31 - Guitar 1 DI"
                "32 - Guitar 2 DI"
                "33 - Guitar 3 DI"
                "34 - Keys 1 L"
                "35 - Keys 1 R"
                "36 - Keys 2 L"
                "37 - Keys 2 R"
                "38 - Keys 3 L"
                "39 - Keys 3 R"
                "40 - Lead Mic L"
                "41 - Lead Mic R"
                "42 - Engineer Vocal"
                "43 - Drummer Mic"
                "44 - Bass Talkback"
                "45 - Guitar 1 Talkback"
                "46 - Guitar 2 Talkback"
                "47 - Keys 1 Talkback"
                "48 - Keys 2 Talkback"
                "49 - Wireless Mic 1"
                "50 - Wireless Mic 2"
                "51 - Producer Talkback"
                "52 - Generic Talkback"
                "53 - Spare 1"
                "54 - Spare 2"
                "55 - Spare 3"
                "56 - Spare 4"
                "57 - Spare 5"
                "58 - Spare 6"
                "59 - Spare 7"
                "60 - Spare 8"
                "61 - Spare 9"
                "62 - Spare 10"
                "63 - Spare 11"
                "64 - Spare 12"
                "65 - Kick In [DSP]"
                "66 - Kick Out [DSP]"
                "67 - Snare Top [DSP]"
                "68 - Snare Bottom [DSP]"
                "69 - Tom 1 [DSP]"
                "70 - Tom 2 [DSP]"
                "71 - Tom 3 [DSP]"
                "72 - Tom 4 [DSP]"
                "73 - Hi-Hat [DSP]"
                "74 - Ride [DSP]"
                "75 - OH L [DSP]"
                "76 - OH R [DSP]"
                "77 - Room L [DSP]"
                "78 - Room R [DSP]"
                "79 - Lead Mic L [DSP]"
                "80 - Lead Mic R [DSP]"
                "81 - Engineer Vocal [DSP]"
                "82 - Drummer Mic [DSP]"
                "83 - Bass Talkback [DSP]"
                "84 - Guitar 1 Talkback [DSP]"
                "85 - Guitar 2 Talkback [DSP]"
                "86 - Keys 1 Talkback [DSP]"
                "87 - Keys 2 Talkback [DSP]"
                "88 - Wireless Mic 1 [DSP]"
                "89 - Wireless Mic 2 [DSP]"
                "90 - Producer Talkback [DSP]"
                "91 - Generic Talkback [DSP]"
                "92 - Bass DI [DSP]"
                "93 - Bass Amp [DSP]"
                "94 - Broadcast Master L [DSP]"
                "95 - Broadcast Master R [DSP]"
                "96 - Engineer Alt Vocal/Talkback [DSP]"
                "97 - System L"
                "98 - System R"
                "99 - System Notifications L"
                "100 - System Notifications R"
                "101 - Voice Chat L"
                "102 - Voice Chat R"
                "103 - DAW L"
                "104 - DAW R"
                "105 - Talkback L"
                "106 - Talkback R"
                "107 - Speakers L"
                "108 - Speakers R"
                "109 - Engineer Mix L"
                "110 - Engineer Mix R"
                "111 - Vocal 1 Mix L"
                "112 - Vocal 1 Mix R"
                "113 - Click"
                "114 - Guide"
                "115 - Drums Mix L"
                "116 - Drums Mix R"
                "117 - Bass Mix L"
                "118 - Bass Mix R"
                "119 - Guitar 1 Mix L"
                "120 - Guitar 1 Mix R"
                "121 - Guitar 2 Mix L"
                "122 - Guitar 2 Mix R"
                "123 - Keys 1 Mix L"
                "124 - Keys 1 Mix R"
                "125 - Keys 2 Mix L"
                "126 - Keys 2 Mix R"
                "127 - Broadcast Mix L"
                "128 - Broadcast Mix R"
              ];
            in
            {
              nixos =
                { pkgs, ... }:
                let
                  infernoPkg = pkgs.callPackage ../../../packages/inferno/inferno.nix { };
                  pcmName = "inferno";
                in
                {
                  environment.systemPackages = [ infernoPkg ];

                  environment.pathsToLink = [ "/lib/alsa-lib" ];
                  environment.variables.ALSA_PLUGIN_DIR = "/run/current-system/sw/lib/alsa-lib";

                  # One shared ALSA PCM device for Inferno; PipeWire exposes it as
                  # a sink and a source node, both backed by the same Dante device.
                  environment.etc."asound.conf".text = ''
                    pcm!default { type null }
                    ctl!default { type null }

                    pcm.inferno {
                      type inferno
                      NAME "${host.name}"
                      DEVICE_ID "${deviceId}"
                      BIND_IP "${bindIp}"
                      SAMPLE_RATE "${toString sampleRate}"
                      RX_CHANNELS "${toString channels}"
                      TX_CHANNELS "${toString channels}"
                      PROCESS_ID "1"
                      ALT_PORT "4400"
                      RX_LATENCY_NS "${toString latencyNs}"
                      TX_LATENCY_NS "${toString latencyNs}"

                      hint {
                        show on
                        description "${host.name} Inferno"
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

              homeManager =
                { pkgs, ... }:
                let
                  applyInfernoRxNames = pkgs.writeShellScript "thebattleship-rename-inferno-rx" ''
                    set -eu
                    device="${host.name}"

                    for attempt in $(seq 1 60); do
                      if netaudio --name "$device" --timeout 2 device show >/dev/null 2>&1; then
                        break
                      fi
                      sleep 2
                    done

                    netaudio --name "$device" channel name 1 "1 - Kick In" --type rx
                    netaudio --name "$device" channel name 2 "2 - Kick Out" --type rx
                    netaudio --name "$device" channel name 3 "3 - Snare Top" --type rx
                    netaudio --name "$device" channel name 4 "4 - Snare Bottom" --type rx
                    netaudio --name "$device" channel name 5 "5 - Tom 1" --type rx
                    netaudio --name "$device" channel name 6 "6 - Tom 2" --type rx
                    netaudio --name "$device" channel name 7 "7 - Tom 3" --type rx
                    netaudio --name "$device" channel name 8 "8 - Tom 4" --type rx
                    netaudio --name "$device" channel name 9 "9 - Hi-Hat" --type rx
                    netaudio --name "$device" channel name 10 "10 - Ride" --type rx
                    netaudio --name "$device" channel name 11 "11 - OH L" --type rx
                    netaudio --name "$device" channel name 12 "12 - OH R" --type rx
                    netaudio --name "$device" channel name 13 "13 - Room L" --type rx
                    netaudio --name "$device" channel name 14 "14 - Room R" --type rx
                    netaudio --name "$device" channel name 15 "15 - Room Far L" --type rx
                    netaudio --name "$device" channel name 16 "16 - Room Far R" --type rx
                    netaudio --name "$device" channel name 17 "17 - Electronic Kit L" --type rx
                    netaudio --name "$device" channel name 18 "18 - Electronic Kit R" --type rx
                    netaudio --name "$device" channel name 19 "19 - Drum Pad L" --type rx
                    netaudio --name "$device" channel name 20 "20 - Drum Pad R" --type rx
                    netaudio --name "$device" channel name 21 "21 - Bass DI" --type rx
                    netaudio --name "$device" channel name 22 "22 - Bass Amp" --type rx
                    netaudio --name "$device" channel name 23 "23 - Bass Synth L" --type rx
                    netaudio --name "$device" channel name 24 "24 - Bass Synth R" --type rx
                    netaudio --name "$device" channel name 25 "25 - Guitar 1 L" --type rx
                    netaudio --name "$device" channel name 26 "26 - Guitar 1 R" --type rx
                    netaudio --name "$device" channel name 27 "27 - Guitar 2 L" --type rx
                    netaudio --name "$device" channel name 28 "28 - Guitar 2 R" --type rx
                    netaudio --name "$device" channel name 29 "29 - Guitar 3 L" --type rx
                    netaudio --name "$device" channel name 30 "30 - Guitar 3 R" --type rx
                    netaudio --name "$device" channel name 31 "31 - Guitar 1 DI" --type rx
                    netaudio --name "$device" channel name 32 "32 - Guitar 2 DI" --type rx
                    netaudio --name "$device" channel name 33 "33 - Guitar 3 DI" --type rx
                    netaudio --name "$device" channel name 34 "34 - Keys 1 L" --type rx
                    netaudio --name "$device" channel name 35 "35 - Keys 1 R" --type rx
                    netaudio --name "$device" channel name 36 "36 - Keys 2 L" --type rx
                    netaudio --name "$device" channel name 37 "37 - Keys 2 R" --type rx
                    netaudio --name "$device" channel name 38 "38 - Keys 3 L" --type rx
                    netaudio --name "$device" channel name 39 "39 - Keys 3 R" --type rx
                    netaudio --name "$device" channel name 40 "40 - Lead Mic L" --type rx
                    netaudio --name "$device" channel name 41 "41 - Lead Mic R" --type rx
                    netaudio --name "$device" channel name 42 "42 - Engineer Vocal" --type rx
                    netaudio --name "$device" channel name 43 "43 - Drummer Mic" --type rx
                    netaudio --name "$device" channel name 44 "44 - Bass Talkback" --type rx
                    netaudio --name "$device" channel name 45 "45 - Guitar 1 Talkback" --type rx
                    netaudio --name "$device" channel name 46 "46 - Guitar 2 Talkback" --type rx
                    netaudio --name "$device" channel name 47 "47 - Keys 1 Talkback" --type rx
                    netaudio --name "$device" channel name 48 "48 - Keys 2 Talkback" --type rx
                    netaudio --name "$device" channel name 49 "49 - Wireless Mic 1" --type rx
                    netaudio --name "$device" channel name 50 "50 - Wireless Mic 2" --type rx
                    netaudio --name "$device" channel name 51 "51 - Producer Talkback" --type rx
                    netaudio --name "$device" channel name 52 "52 - Generic Talkback" --type rx
                    netaudio --name "$device" channel name 53 "53 - Spare 1" --type rx
                    netaudio --name "$device" channel name 54 "54 - Spare 2" --type rx
                    netaudio --name "$device" channel name 55 "55 - Spare 3" --type rx
                    netaudio --name "$device" channel name 56 "56 - Spare 4" --type rx
                    netaudio --name "$device" channel name 57 "57 - Spare 5" --type rx
                    netaudio --name "$device" channel name 58 "58 - Spare 6" --type rx
                    netaudio --name "$device" channel name 59 "59 - Spare 7" --type rx
                    netaudio --name "$device" channel name 60 "60 - Spare 8" --type rx
                    netaudio --name "$device" channel name 61 "61 - Spare 9" --type rx
                    netaudio --name "$device" channel name 62 "62 - Spare 10" --type rx
                    netaudio --name "$device" channel name 63 "63 - Spare 11" --type rx
                    netaudio --name "$device" channel name 64 "64 - Spare 12" --type rx
                    netaudio --name "$device" channel name 65 "65 - Kick In [DSP]" --type rx
                    netaudio --name "$device" channel name 66 "66 - Kick Out [DSP]" --type rx
                    netaudio --name "$device" channel name 67 "67 - Snare Top [DSP]" --type rx
                    netaudio --name "$device" channel name 68 "68 - Snare Bottom [DSP]" --type rx
                    netaudio --name "$device" channel name 69 "69 - Tom 1 [DSP]" --type rx
                    netaudio --name "$device" channel name 70 "70 - Tom 2 [DSP]" --type rx
                    netaudio --name "$device" channel name 71 "71 - Tom 3 [DSP]" --type rx
                    netaudio --name "$device" channel name 72 "72 - Tom 4 [DSP]" --type rx
                    netaudio --name "$device" channel name 73 "73 - Hi-Hat [DSP]" --type rx
                    netaudio --name "$device" channel name 74 "74 - Ride [DSP]" --type rx
                    netaudio --name "$device" channel name 75 "75 - OH L [DSP]" --type rx
                    netaudio --name "$device" channel name 76 "76 - OH R [DSP]" --type rx
                    netaudio --name "$device" channel name 77 "77 - Room L [DSP]" --type rx
                    netaudio --name "$device" channel name 78 "78 - Room R [DSP]" --type rx
                    netaudio --name "$device" channel name 79 "79 - Lead Mic L [DSP]" --type rx
                    netaudio --name "$device" channel name 80 "80 - Lead Mic R [DSP]" --type rx
                    netaudio --name "$device" channel name 81 "81 - Engineer Vocal [DSP]" --type rx
                    netaudio --name "$device" channel name 82 "82 - Drummer Mic [DSP]" --type rx
                    netaudio --name "$device" channel name 83 "83 - Bass Talkback [DSP]" --type rx
                    netaudio --name "$device" channel name 84 "84 - Guitar 1 Talkback [DSP]" --type rx
                    netaudio --name "$device" channel name 85 "85 - Guitar 2 Talkback [DSP]" --type rx
                    netaudio --name "$device" channel name 86 "86 - Keys 1 Talkback [DSP]" --type rx
                    netaudio --name "$device" channel name 87 "87 - Keys 2 Talkback [DSP]" --type rx
                    netaudio --name "$device" channel name 88 "88 - Wireless Mic 1 [DSP]" --type rx
                    netaudio --name "$device" channel name 89 "89 - Wireless Mic 2 [DSP]" --type rx
                    netaudio --name "$device" channel name 90 "90 - Producer Talkback [DSP]" --type rx
                    netaudio --name "$device" channel name 91 "91 - Generic Talkback [DSP]" --type rx
                    netaudio --name "$device" channel name 92 "92 - Bass DI [DSP]" --type rx
                    netaudio --name "$device" channel name 93 "93 - Bass Amp [DSP]" --type rx
                    netaudio --name "$device" channel name 94 "94 - Broadcast Master L [DSP]" --type rx
                    netaudio --name "$device" channel name 95 "95 - Broadcast Master R [DSP]" --type rx
                    netaudio --name "$device" channel name 96 "96 - Engineer Alt Vocal/Talkback [DSP]" --type rx
                    netaudio --name "$device" channel name 97 "97 - System L" --type rx
                    netaudio --name "$device" channel name 98 "98 - System R" --type rx
                    netaudio --name "$device" channel name 99 "99 - System Notifications L" --type rx
                    netaudio --name "$device" channel name 100 "100 - System Notifications R" --type rx
                    netaudio --name "$device" channel name 101 "101 - Voice Chat L" --type rx
                    netaudio --name "$device" channel name 102 "102 - Voice Chat R" --type rx
                    netaudio --name "$device" channel name 103 "103 - DAW L" --type rx
                    netaudio --name "$device" channel name 104 "104 - DAW R" --type rx
                    netaudio --name "$device" channel name 105 "105 - Talkback L" --type rx
                    netaudio --name "$device" channel name 106 "106 - Talkback R" --type rx
                    netaudio --name "$device" channel name 107 "107 - Speakers L" --type rx
                    netaudio --name "$device" channel name 108 "108 - Speakers R" --type rx
                    netaudio --name "$device" channel name 109 "109 - Engineer Mix L" --type rx
                    netaudio --name "$device" channel name 110 "110 - Engineer Mix R" --type rx
                    netaudio --name "$device" channel name 111 "111 - Vocal 1 Mix L" --type rx
                    netaudio --name "$device" channel name 112 "112 - Vocal 1 Mix R" --type rx
                    netaudio --name "$device" channel name 113 "113 - Click" --type rx
                    netaudio --name "$device" channel name 114 "114 - Guide" --type rx
                    netaudio --name "$device" channel name 115 "115 - Drums Mix L" --type rx
                    netaudio --name "$device" channel name 116 "116 - Drums Mix R" --type rx
                    netaudio --name "$device" channel name 117 "117 - Bass Mix L" --type rx
                    netaudio --name "$device" channel name 118 "118 - Bass Mix R" --type rx
                    netaudio --name "$device" channel name 119 "119 - Guitar 1 Mix L" --type rx
                    netaudio --name "$device" channel name 120 "120 - Guitar 1 Mix R" --type rx
                    netaudio --name "$device" channel name 121 "121 - Guitar 2 Mix L" --type rx
                    netaudio --name "$device" channel name 122 "122 - Guitar 2 Mix R" --type rx
                    netaudio --name "$device" channel name 123 "123 - Keys 1 Mix L" --type rx
                    netaudio --name "$device" channel name 124 "124 - Keys 1 Mix R" --type rx
                    netaudio --name "$device" channel name 125 "125 - Keys 2 Mix L" --type rx
                    netaudio --name "$device" channel name 126 "126 - Keys 2 Mix R" --type rx
                    netaudio --name "$device" channel name 127 "127 - Broadcast Mix L" --type rx
                    netaudio --name "$device" channel name 128 "128 - Broadcast Mix R" --type rx

                    netaudio server restart
                  '';
                in
                {
                  systemd.user.services.netaudio-inferno-rx-channel-names = {
                    Unit = {
                      Description = "Apply Inferno RX channel names via netaudio";
                      After = [
                        "pipewire.service"
                        "wireplumber.service"
                        "pipewire-pulse.service"
                      ];
                      Wants = [
                        "pipewire.service"
                        "wireplumber.service"
                        "pipewire-pulse.service"
                      ];
                    };
                    Service = {
                      Type = "oneshot";
                      ExecStart = "${applyInfernoRxNames}";
                    };
                    Install.WantedBy = [ "default.target" ];
                  };
                };
            }
          )
        ];
      };
  };
}
