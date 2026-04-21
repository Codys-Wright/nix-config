{ lib }:
let
  mkChannelPositions = channels: override:
    if override != null then override else
      if channels == 2 then [ "FL" "FR" ]
      else if channels == 8 then [ "FL" "FR" "RL" "RR" "FC" "LFE" "SL" "SR" ]
      else if channels == 16 then [
        "FL" "FR"
        "RL" "RR"
        "FC" "LFE"
        "SL" "SR"
        "AUX0" "AUX1"
        "AUX2" "AUX3"
        "AUX4" "AUX5"
        "AUX6" "AUX7"
      ]
      else builtins.genList (i: "CH${toString (i + 1)}") channels;

  mkPositionString = positions: lib.concatStringsSep " " positions;
in
{
  name,
  bindIp,
  deviceId,
  description ? "${name} Inferno Dante tools and system-wide ALSA virtual soundcard",
  pcmName ? "inferno",
  channels ? 16,
  latencyNs ? 1000000,
  rxLatencyNs ? latencyNs,
  txLatencyNs ? latencyNs,
  sampleRate ? 48000,
  audioPositions ? null,
  clockPath ? null,
  processId ? "1",
  altPort ? "4400",
  headroom ? 128,
  card ? 999,
  periodSize ? 1024,
  periodNum ? 4,
  package ? null,
}:
let
  positions = mkChannelPositions channels audioPositions;
  positionString = mkPositionString positions;
  clockPathLine = lib.optionalString (clockPath != null) ''
            CLOCK_PATH "${clockPath}"'';
in
{
  inherit description;

  nixos = { pkgs, ... }:
    let
      infernoPkg = if package != null then package else pkgs.callPackage ../../packages/inferno/inferno.nix { };
      sinkScript = pkgs.writeShellScript "inferno-start-pipewire-sink" ''
        ${pkgs.pipewire}/bin/pw-cli create-node adapter '{ object.linger=1 factory.name=api.alsa.pcm.sink node.name="Inferno sink" node.description="Inferno Dante Sink" media.class=Audio/Sink audio.channels=${toString channels} audio.position=[ ${positionString} ] api.alsa.path="${pcmName}" session.suspend-timeout-seconds=0 node.pause-on-idle=false node.suspend-on-idle=false node.always-process=true api.alsa.headroom=${toString headroom} api.alsa.pcm.card=${toString card} api.alsa.period-size=${toString periodSize} api.alsa.period-num=${toString periodNum} }'
      '';
      sourceScript = pkgs.writeShellScript "inferno-start-pipewire-source" ''
        ${pkgs.pipewire}/bin/pw-cli create-node adapter '{ object.linger=1 factory.name=api.alsa.pcm.source node.name="Inferno source" node.description="Inferno Dante Source" media.class=Audio/Source audio.channels=${toString channels} audio.position=[ ${positionString} ] api.alsa.path="${pcmName}" session.suspend-timeout-seconds=0 node.pause-on-idle=false node.suspend-on-idle=false node.always-process=true api.alsa.headroom=${toString headroom} api.alsa.pcm.card=${toString card} api.alsa.period-size=${toString periodSize} api.alsa.period-num=${toString periodNum} }'
      '';
    in
    {
      environment.systemPackages = [ infernoPkg ];
      environment.pathsToLink = [ "/lib/alsa-lib" ];
      environment.variables = {
        ALSA_PLUGIN_DIR = "/run/current-system/sw/lib/alsa-lib";
      };

      users.groups.clock = { };

      environment.etc."asound.conf".text = ''
        pcm!default { type null }
        ctl!default { type null }

        pcm.${pcmName} {
          type inferno
          NAME "${name}"
          DEVICE_ID "${deviceId}"
          BIND_IP "${bindIp}"
          # Leave CLOCK_PATH unset so Inferno follows Statime's exported usrvclock,
          # which in turn tracks the Dante/PTP grandmaster.
          PROCESS_ID "${processId}"
          ALT_PORT "${altPort}"
          SAMPLE_RATE "${toString sampleRate}"
          RX_CHANNELS "${toString channels}"
          TX_CHANNELS "${toString channels}"
          RX_LATENCY_NS "${toString rxLatencyNs}"
          TX_LATENCY_NS "${toString txLatencyNs}"
          ${clockPathLine}

          hint {
            show on
            description "${name} Inferno virtual device"
          }
        }
      '';

      systemd.services.pipewire.serviceConfig.SystemCallFilter = [ "@clock" ];

      systemd.services.inferno-pipewire-sink = {
        description = "${description} PipeWire sink";
        after = [
          "pipewire.service"
          "statime-inferno.service"
        ];
        requires = [ "pipewire.service" ];
        wants = [ "statime-inferno.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          Environment = [
            "ALSA_PLUGIN_DIR=/run/current-system/sw/lib/alsa-lib"
            "ALSA_CONFIG_PATH=/etc/asound.conf"
            "XDG_RUNTIME_DIR=/run/pipewire"
          ];
          ExecStart = "${sinkScript}";
        };
      };

      systemd.services.inferno-pipewire-source = {
        description = "${description} PipeWire source";
        after = [
          "pipewire.service"
          "inferno-pipewire-sink.service"
          "statime-inferno.service"
        ];
        requires = [ "pipewire.service" ];
        wants = [ "statime-inferno.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          Environment = [
            "ALSA_PLUGIN_DIR=/run/current-system/sw/lib/alsa-lib"
            "ALSA_CONFIG_PATH=/etc/asound.conf"
            "XDG_RUNTIME_DIR=/run/pipewire"
          ];
          ExecStart = "${sourceScript}";
        };
      };
    };
}
