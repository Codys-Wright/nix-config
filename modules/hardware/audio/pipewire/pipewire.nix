# PipeWire audio sub-aspect (can be included independently)
{
  fleet,
  den,
  lib,
  ...
}:
let
  pw = import ../../../../lib/audio/pipewire/common.nix { inherit lib; };
  stereoPositions = pw.mkChannelPositions 2 null;
  dawPositions = pw.mkChannelPositions 16 null;
in
{
  fleet.hardware._.audio._.pipewire = {
    description = "PipeWire audio system with low-latency configuration";

    includes = [ (den.lib.groups [ "audio" ]) ];

    nixos = pw.mkPipewireNixos {
      systemPackages =
        pkgs: with pkgs; [
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

      defaultSink = "system_audio";
      defaultSource = "talkback_mic";
      loopbacks = [
        {
          description = "Yamaha TF Stereo";
          nodeName = "yamaha_tf_stereo";
          captureProps = {
            "media.class" = "Audio/Sink";
            "audio.position" = stereoPositions;
          };
          playbackProps = {
            "target.object" = "alsa_output.usb-Yamaha_Corporation_Yamaha_TF-00.multichannel-output";
            "audio.position" = [
              "AUX0"
              "AUX1"
            ];
            "node.passive" = true;
          };
        }
        {
          description = "Broadcast";
          captureProps = {
            "node.name" = "broadcast";
            "media.class" = "Audio/Sink";
            "audio.position" = stereoPositions;
            "priority.session" = 500;
          };
          playbackProps = {
            "node.name" = "broadcast.playback";
            "target.object" = "Inferno sink";
            "node.passive" = true;
            "stream.dont-remix" = true;
            "audio.position" = stereoPositions;
          };
        }
        {
          description = "System Audio";
          captureProps = {
            "node.name" = "system_audio";
            "media.class" = "Audio/Sink";
            "audio.position" = stereoPositions;
            "priority.session" = 1000;
          };
          playbackProps = {
            "node.name" = "system-audio.playback";
            "target.object" = "Inferno sink";
            "node.passive" = true;
            "stream.dont-remix" = true;
            "audio.position" = stereoPositions;
          };
        }
        {
          description = "System Notifications";
          captureProps = {
            "node.name" = "system_notifications";
            "media.class" = "Audio/Sink";
            "audio.position" = stereoPositions;
            "priority.session" = 800;
          };
          playbackProps = {
            "node.name" = "system-notifications.playback";
            "target.object" = "system_audio";
            "node.passive" = true;
            "stream.dont-remix" = true;
            "audio.position" = stereoPositions;
          };
        }
        {
          description = "Voice Chat";
          captureProps = {
            "node.name" = "voice_chat";
            "media.class" = "Audio/Sink";
            "audio.position" = stereoPositions;
            "priority.session" = 850;
          };
          playbackProps = {
            "node.name" = "voice-chat.playback";
            "target.object" = "broadcast";
            "node.passive" = true;
            "stream.dont-remix" = true;
            "audio.position" = stereoPositions;
          };
        }
        {
          description = "Daw";
          captureProps = {
            "node.name" = "daw";
            "media.class" = "Audio/Sink";
            "audio.channels" = 16;
            "audio.position" = dawPositions;
            "priority.session" = 950;
          };
          playbackProps = {
            "node.name" = "daw.playback";
            "target.object" = "Inferno sink";
            "node.passive" = true;
            "stream.dont-remix" = true;
            "audio.position" = dawPositions;
          };
        }
        {
          description = "Daw Broadcast";
          captureProps = {
            "node.name" = "daw_broadcast.capture";
            "target.object" = "daw";
            "stream.capture.sink" = true;
            "node.passive" = true;
            "stream.dont-remix" = true;
          };
          playbackProps = {
            "node.name" = "daw_broadcast";
            "media.class" = "Audio/Source";
            "audio.position" = stereoPositions;
            "priority.session" = 900;
          };
        }
        {
          description = "Talkback Mic";
          captureProps = {
            "node.name" = "talkback_mic.capture";
            "target.object" = "alsa_input.usb-Insta360_Insta360_Link_2_Pro-02.mono-fallback";
            "node.passive" = true;
            "stream.dont-remix" = true;
            "audio.position" = [ "MONO" ];
          };
          playbackProps = {
            "node.name" = "talkback_mic";
            "media.class" = "Audio/Source";
            "audio.position" = [ "MONO" ];
            "priority.session" = 1000;
          };
        }
      ];

      routes = [
        {
          matches = [
            { "application.name" = "Brave Browser"; }
            { "application.name" = "Firefox"; }
            { "application.name" = "Chromium"; }
            { "application.name" = "Google Chrome"; }
            { "application.name" = "Zen Browser"; }
          ];
          targetObject = "system_audio";
        }
        {
          matches = [
            { "application.name" = "Discord"; }
            { "application.name" = "Discord Canary"; }
            { "application.name" = "Vesktop"; }
            { "application.name" = "WebCord"; }
            { "application.name" = "Microsoft Teams"; }
            { "application.name" = "Teams for Linux"; }
          ];
          targetObject = "voice_chat";
        }
        {
          matches = [
            { "application.name" = "REAPER"; }
            { "application.name" = "Reaper"; }
            { "application.name" = "reaper"; }
          ];
          targetObject = "daw";
        }
        {
          matches = [
            { "application.name" = "OBS Studio"; }
            { "application.name" = "OBS"; }
          ];
          targetObject = "broadcast";
        }
        {
          matches = [ { "media.role" = "event"; } ];
          targetObject = "system_notifications";
        }
        {
          matches = [
            { "application.process.binary" = "reaper"; }
            { "application.process.binary" = "reaper.exe"; }
          ];
          targetObject = "daw";
        }
        {
          matches = [
            { "application.process.binary" = "discord"; }
            { "application.process.binary" = "Discord"; }
            { "application.process.binary" = "discord-canary"; }
            { "application.process.binary" = "vesktop"; }
            { "application.process.binary" = "WebCord"; }
            { "application.process.binary" = "teams"; }
            { "application.process.binary" = "teams-for-linux"; }
          ];
          targetObject = "voice_chat";
        }
        {
          matches = [
            { "application.process.binary" = "obs"; }
            { "application.process.binary" = "obs64"; }
            { "application.process.binary" = "com.obsproject.Studio"; }
          ];
          targetObject = "broadcast";
        }
        {
          matches = [
            { "application.process.binary" = "brave-browser"; }
            { "application.process.binary" = "firefox"; }
            { "application.process.binary" = "chromium"; }
            { "application.process.binary" = "google-chrome"; }
            { "application.process.binary" = "zen-browser"; }
          ];
          targetObject = "system_audio";
        }
      ];
    };
  };
}
