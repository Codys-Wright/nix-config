{ lib }:
let
  mkChannelPositions =
    channels: override:
    if override != null then
      override
    else if channels == 2 then
      [
        "FL"
        "FR"
      ]
    else if channels == 8 then
      [
        "FL"
        "FR"
        "RL"
        "RR"
        "FC"
        "LFE"
        "SL"
        "SR"
      ]
    else if channels == 16 then
      [
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
      ]
    else if channels == 128 then
      builtins.genList (i: "AUX${toString i}") channels
    else
      builtins.genList (i: "CH${toString (i + 1)}") channels;

  mkPositionString = positions: lib.concatStringsSep " " positions;

  mkStudio128Positions = [
    "Kick In Raw"
    "Kick Out Raw"
    "Snare Top Raw"
    "Snare Bottom Raw"
    "Tom 1 Raw"
    "Tom 2 Raw"
    "Tom 3 Raw"
    "Tom 4 Raw"
    "Hi-Hat Raw"
    "Ride Raw"
    "OH L Raw"
    "OH R Raw"
    "Room L Raw"
    "Room R Raw"
    "Room Far L Raw"
    "Room Far R Raw"
    "Drum Aux 1 Raw"
    "Drum Aux 2 Raw"
    "Drum Aux 3 Raw"
    "Drum Aux 4 Raw"
    "Bass DI Raw"
    "Bass Amp Raw"
    "Bass Synth L Raw"
    "Bass Synth R Raw"
    "Guitar 1 L Raw"
    "Guitar 1 R Raw"
    "Guitar 2 L Raw"
    "Guitar 2 R Raw"
    "Guitar 3 L Raw"
    "Guitar 3 R Raw"
    "Guitar 1 DI Raw"
    "Guitar 2 DI Raw"
    "Guitar 3 DI Raw"
    "Keys 1 L Raw"
    "Keys 1 R Raw"
    "Keys 2 L Raw"
    "Keys 2 R Raw"
    "Keys 3 L Raw"
    "Keys 3 R Raw"
    "Lead Mic L Raw"
    "Lead Mic R Raw"
    "Engineer Vocal Raw"
    "Drummer Mic Raw"
    "Bass Talkback Raw"
    "Guitar 1 Talkback Raw"
    "Guitar 2 Talkback Raw"
    "Keys 1 Talkback Raw"
    "Keys 2 Talkback Raw"
    "Wireless Mic 1 Raw"
    "Wireless Mic 2 Raw"
    "Producer Talkback Raw"
    "Generic Talkback Raw"
    "Spare Raw 1"
    "Spare Raw 2"
    "Spare Raw 3"
    "Spare Raw 4"
    "Spare Raw 5"
    "Spare Raw 6"
    "Spare Raw 7"
    "Spare Raw 8"
    "Spare Raw 9"
    "Spare Raw 10"
    "Spare Raw 11"
    "Spare Raw 12"
    "Kick In Proc"
    "Kick Out Proc"
    "Snare Top Proc"
    "Snare Bottom Proc"
    "Tom 1 Proc"
    "Tom 2 Proc"
    "Tom 3 Proc"
    "Tom 4 Proc"
    "Hi-Hat Proc"
    "Ride Proc"
    "OH L Proc"
    "OH R Proc"
    "Room L Proc"
    "Room R Proc"
    "Lead Mic L Proc"
    "Lead Mic R Proc"
    "Engineer Vocal Proc"
    "Drummer Mic Proc"
    "Bass Talkback Proc"
    "Guitar 1 Talkback Proc"
    "Guitar 2 Talkback Proc"
    "Keys 1 Talkback Proc"
    "Keys 2 Talkback Proc"
    "Wireless Mic 1 Proc"
    "Wireless Mic 2 Proc"
    "Producer Talkback Proc"
    "Generic Talkback Proc"
    "Bass DI Proc"
    "Bass Amp Proc"
    "Broadcast Master L Proc"
    "Broadcast Master R Proc"
    "Engineer Alt Vocal/Talkback Proc"
    "System L"
    "System R"
    "System Notifications L"
    "System Notifications R"
    "Voice Chat L"
    "Voice Chat R"
    "DAW L"
    "DAW R"
    "Talkback L"
    "Talkback R"
    "Speakers L"
    "Speakers R"
    "Engineer Mix L"
    "Engineer Mix R"
    "Vocal 1 Mix L"
    "Vocal 1 Mix R"
    "Vocal 2 Mix M"
    "Vocal 3 Mix M"
    "Drums Mix L"
    "Drums Mix R"
    "Bass Mix L"
    "Bass Mix R"
    "Guitar 1 Mix L"
    "Guitar 1 Mix R"
    "Guitar 2 Mix L"
    "Guitar 2 Mix R"
    "Keys Mix L"
    "Keys Mix R"
    "Keys 2 Mix L"
    "Keys 2 Mix R"
    "Broadcast Mix L"
    "Broadcast Mix R"
  ];
in
{
  inherit mkChannelPositions mkPositionString mkStudio128Positions;

  mkInfernoAspect =
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
      clockPathLine = lib.optionalString (clockPath != null) ''CLOCK_PATH "${clockPath}"'';
    in
    {
      inherit description;

      nixos =
        { pkgs, ... }:
        let
          infernoPkg =
            if package != null then package else pkgs.callPackage ../../packages/inferno/inferno.nix { };
          cleanupNodeScript = pkgs.writeShellScript "inferno-cleanup-node" ''
            set -euo pipefail
            wanted="$1"
            export XDG_RUNTIME_DIR=/run/pipewire

            ${pkgs.pipewire}/bin/pw-dump \
              | ${pkgs.jq}/bin/jq -r --arg wanted "$wanted" '
                .[]
                | select(.type == "PipeWire:Interface:Node/3")
                | select(.info.props["node.name"] == $wanted)
                | .id
              ' \
              | while IFS= read -r id; do
                [ -n "$id" ] || continue
                ${pkgs.pipewire}/bin/pw-cli destroy "$id" || true
              done
          '';
          sinkScript = pkgs.writeShellScript "inferno-start-pipewire-sink" ''
            set -euo pipefail
            export XDG_RUNTIME_DIR=/run/pipewire
            ${cleanupNodeScript} "Inferno sink"

            ${pkgs.pipewire}/bin/pw-cli create-node adapter '{ object.linger=1 factory.name=api.alsa.pcm.sink node.name="Inferno sink" node.description="Inferno Dante Sink" media.class=Stream/Input/Audio priority.session=2000 audio.channels=${toString channels} audio.position=[ ${positionString} ] api.alsa.path="${pcmName}" api.alsa.soft-mixer=true session.suspend-timeout-seconds=0 node.pause-on-idle=false node.suspend-on-idle=false node.always-process=true api.alsa.headroom=${toString headroom} api.alsa.pcm.card=${toString card} api.alsa.period-size=${toString periodSize} api.alsa.period-num=${toString periodNum} }'
          '';
          sourceScript = pkgs.writeShellScript "inferno-start-pipewire-source" ''
            set -euo pipefail
            export XDG_RUNTIME_DIR=/run/pipewire
            ${cleanupNodeScript} "Inferno source"

            ${pkgs.pipewire}/bin/pw-cli create-node adapter '{ object.linger=1 factory.name=api.alsa.pcm.source node.name="Inferno source" node.description="Inferno Dante Source" media.class=Stream/Output/Audio priority.session=1900 audio.channels=${toString channels} audio.position=[ ${positionString} ] api.alsa.path="${pcmName}" session.suspend-timeout-seconds=0 node.pause-on-idle=false node.suspend-on-idle=false node.always-process=true api.alsa.headroom=${toString headroom} api.alsa.pcm.card=${toString card} api.alsa.period-size=${toString periodSize} api.alsa.period-num=${toString periodNum} }'
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
    };

  mkStatimeNixos =
    {
      name,
      interface,
      deviceName,
      configFile ? "inferno/statime-ptpv1.toml",
      description ? "Statime Inferno PTP daemon",
      serviceName ? "statime-inferno",
      preferredLeaderServiceName ? "dante-galaxy32-preferred-leader",
      preferredLeaderDescription ? "Ensure ${deviceName} is preferred leader for Dante PTP",
      preferredLeaderArgs ? [
        "--name"
        deviceName
        "device"
        "config"
        "preferred-leader"
        "on"
      ],
      loglevel ? "warn",
      sdoId ? 0,
      domain ? 0,
      priority1 ? 251,
      virtualSystemClock ? true,
      virtualSystemClockBase ? "monotonic_raw",
      usrvclockExport ? true,
      networkMode ? "ipv4",
      hardwareClock ? "none",
      protocolVersion ? "PTPv1",
      interfaceComment ? null,
      after ? [ "network-online.target" ],
      wants ? [ "network-online.target" ],
      wantedBy ? [ "multi-user.target" ],
      package ? null,
      netaudioPackage ? null,
    }:
    { pkgs, ... }:
    let
      statimePkg =
        if package != null then package else pkgs.callPackage ../../packages/statime/statime.nix { };
      netaudioPkg =
        if netaudioPackage != null then
          netaudioPackage
        else
          pkgs.callPackage ../../packages/netaudio/netaudio.nix { };
      interfaceCommentText = lib.optionalString (interfaceComment != null) "# ${interfaceComment}";
    in
    {
      environment.systemPackages = [
        statimePkg
        netaudioPkg
      ];

      environment.etc."${configFile}".text = ''
        loglevel = "${loglevel}"
        sdo-id = ${toString sdoId}
        domain = ${toString domain}
        priority1 = ${toString priority1}
        virtual-system-clock = ${if virtualSystemClock then "true" else "false"}
        virtual-system-clock-base = "${virtualSystemClockBase}"
        usrvclock-export = ${if usrvclockExport then "true" else "false"}

        [[port]]
        ${interfaceCommentText}
        interface = "${interface}"
        network-mode = "${networkMode}"
        hardware-clock = "${hardwareClock}"
        protocol-version = "${protocolVersion}"
      '';

      systemd.services.${serviceName} = {
        description = description;
        inherit after wants wantedBy;
        serviceConfig = {
          Type = "simple";
          ExecStart = "${statimePkg}/bin/statime --config /etc/${configFile}";
          Restart = "on-failure";
          RestartSec = "3s";
        };
      };

      systemd.services.${preferredLeaderServiceName} = {
        description = preferredLeaderDescription;
        wantedBy = wantedBy;
        after = after ++ [ "${serviceName}.service" ];
        wants = wants ++ [ "${serviceName}.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${netaudioPkg}/bin/netaudio ${lib.escapeShellArgs preferredLeaderArgs}";
        };
      };
    };
}
