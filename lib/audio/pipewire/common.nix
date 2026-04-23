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
    else
      builtins.genList (i: "CH${toString (i + 1)}") channels;

  mkPositionString = positions: lib.concatStringsSep " " positions;

  mkPositionCsv = positions: lib.concatStringsSep "," positions;

  getNestedOrFlat =
    attrs: nestedPath: flatKey: default:
    let
      nestedValue = lib.attrByPath nestedPath null attrs;
    in
    if nestedValue != null then nestedValue else lib.attrByPath [ flatKey ] default attrs;

  mkLoopbackModule =
    {
      description,
      captureProps,
      playbackProps,
      nodeName ? null,
    }:
    let
      captureProps' =
        if nodeName != null && !(captureProps ? "node.name") && !(captureProps ? node.name) then
          captureProps // { "node.name" = nodeName; }
        else
          captureProps;
    in
    {
      name = "libpipewire-module-loopback";
      args = lib.filterAttrs (_: v: v != null) {
        "node.description" = description;
        "capture.props" = captureProps';
        "playback.props" = playbackProps;
      };
    };

  mkRouteRule =
    {
      matches,
      targetObject,
    }:
    {
      inherit matches;
      actions = {
        "update-props" = {
          "target.object" = targetObject;
        };
      };
    };
in
{
  inherit
    mkChannelPositions
    mkPositionString
    mkPositionCsv
    mkLoopbackModule
    mkRouteRule
    ;

  mkPipewireNixos =
    {
      description ? "PipeWire audio system with low-latency configuration",
      systemWide ? true,
      defaultClockRate ? 48000,
      defaultClockQuantum ? 256,
      defaultClockMinQuantum ? 32,
      defaultClockMaxQuantum ? 1024,
      pulseMinReq ? "32/48000",
      pulseDefaultReq ? "256/48000",
      pulseMaxReq ? "1024/48000",
      pulseMinQuantum ? pulseMinReq,
      pulseMaxQuantum ? pulseMaxReq,
      resampleQuality ? 4,
      systemPackages ? (_: [ ]),
      extraPipewireConfig ? { },
      extraPulseConfig ? { },
      extraWireplumberConfig ? { },
      loopbacks ? [ ],
      routes ? [ ],
      defaultSink ? null,
      defaultSource ? null,
      clockGroup ? "clock",
      alsaPluginDir ? "/run/current-system/sw/lib/alsa-lib",
      pipewireRuntimeDir ? "/run/pipewire",
      socketMode ? "0660",
      socketGroup ? "audio",
    }:
    { pkgs, ... }:
    let
      routeRules = map mkRouteRule routes;
      defaultConfig = lib.optionalAttrs (defaultSink != null || defaultSource != null) {
        "wireplumber.settings" = lib.filterAttrs (_: v: v != null) {
          "default.configured.audio.sink" = defaultSink;
          "default.configured.audio.source" = defaultSource;
        };
      };
      withTargetPolicy =
        props:
        if (getNestedOrFlat props [ "target" "object" ] "target.object" null) != null then
          props
          // {
            "node.dont-fallback" = true;
            "node.linger" = true;
          }
        else
          props;
      loopbacks' = map (
        loopback:
        let
          captureProps0 =
            if
              loopback ? nodeName
              && loopback.nodeName != null
              && !(loopback.captureProps ? "node.name")
              && !(loopback.captureProps ? node.name)
            then
              loopback.captureProps // { "node.name" = loopback.nodeName; }
            else
              loopback.captureProps;
        in
        loopback
        // {
          captureProps = withTargetPolicy captureProps0;
          playbackProps = withTargetPolicy loopback.playbackProps;
        }
      ) loopbacks;
      loopbackModules = map (
        loopback:
        mkLoopbackModule {
          inherit (loopback) description captureProps playbackProps;
          nodeName = loopback.nodeName or null;
        }
      ) loopbacks';
      defaultAudioScript = pkgs.writeShellScript "pipewire-set-default-audio" ''
        set -euo pipefail
        export XDG_RUNTIME_DIR=${pipewireRuntimeDir}

        ${lib.optionalString (defaultSink != null) ''
          for _ in $(seq 1 30); do
            sink_id="$(${pkgs.pipewire}/bin/pw-dump | ${pkgs.jq}/bin/jq -r '.[] | select(.type=="PipeWire:Interface:Node/3" and .info.props["node.name"]=="${defaultSink}") | .id' | head -n1)"
            if [ -n "$sink_id" ] && [ "$sink_id" != "null" ]; then
              ${pkgs.pipewire}/bin/wpctl set-default "$sink_id"
              break
            fi
            ${pkgs.coreutils}/bin/sleep 1
          done
        ''}

        ${lib.optionalString (defaultSource != null) ''
          for _ in $(seq 1 30); do
            source_id="$(${pkgs.pipewire}/bin/pw-dump | ${pkgs.jq}/bin/jq -r '.[] | select(.type=="PipeWire:Interface:Node/3" and .info.props["node.name"]=="${defaultSource}") | .id' | head -n1)"
            if [ -n "$source_id" ] && [ "$source_id" != "null" ]; then
              ${pkgs.pipewire}/bin/wpctl set-default "$source_id"
              break
            fi
            ${pkgs.coreutils}/bin/sleep 1
          done
        ''}
      '';
    in
    {
      security.rtkit.enable = true;

      services.pipewire = {
        enable = true;
        inherit systemWide;

        alsa = {
          enable = true;
          support32Bit = true;
        };

        jack.enable = true;
        pulse.enable = true;
        wireplumber.enable = true;

        extraConfig = {
          pipewire = {
            "92-low-latency" = {
              "context.properties" = {
                "default.clock.rate" = defaultClockRate;
                "default.clock.quantum" = defaultClockQuantum;
                "default.clock.min-quantum" = defaultClockMinQuantum;
                "default.clock.max-quantum" = defaultClockMaxQuantum;
              };
            };
          }
          // lib.optionalAttrs (loopbackModules != [ ]) {
            "93-studio-loopbacks" = {
              "context.modules" = loopbackModules;
            };
          }
          // extraPipewireConfig;

          pipewire-pulse = {
            "92-low-latency" = {
              "pulse.properties" = {
                pulse.min.req = pulseMinReq;
                pulse.default.req = pulseDefaultReq;
                pulse.max.req = pulseMaxReq;
                pulse.min.quantum = pulseMinQuantum;
                pulse.max.quantum = pulseMaxQuantum;
              };
              "stream.properties" = {
                node.latency = pulseDefaultReq;
                resample.quality = resampleQuality;
              };
            };

            "93-studio-routing" = lib.optionalAttrs (routes != [ ]) {
              "stream.rules" = routeRules;
            };
          }
          // extraPulseConfig;
        };
      };

      services.pipewire.wireplumber.extraConfig."51-studio-defaults" =
        defaultConfig // extraWireplumberConfig;

      systemd.services =
        lib.optionalAttrs (defaultSink != null || defaultSource != null) {
          pipewire-set-default-audio = {
            description = "Set PipeWire default audio nodes";
            after = [
              "pipewire.service"
              "wireplumber.service"
            ];
            wants = [
              "pipewire.service"
              "wireplumber.service"
            ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              Type = "oneshot";
              Environment = [ "XDG_RUNTIME_DIR=${pipewireRuntimeDir}" ];
              ExecStart = "${defaultAudioScript}";
            };
          };
        }
        // {
          pipewire.serviceConfig.Environment = [
            "ALSA_PLUGIN_DIR=${alsaPluginDir}"
          ];
          pipewire.serviceConfig.SystemCallFilter = [ "@clock" ];

          pipewire-pulse = {
            wantedBy = [ "multi-user.target" ];
            serviceConfig.Environment = [
              "PIPEWIRE_RUNTIME_DIR=${pipewireRuntimeDir}"
              "ALSA_PLUGIN_DIR=${alsaPluginDir}"
            ];
          };

          wireplumber = {
            wantedBy = [ "multi-user.target" ];
            serviceConfig.Environment = [
              "PIPEWIRE_RUNTIME_DIR=${pipewireRuntimeDir}"
            ];
          };
        };

      environment.systemPackages = systemPackages pkgs;

      users.groups.${clockGroup} = { };
      users.users.pipewire.extraGroups = [ clockGroup ];

      systemd.sockets.pipewire.socketConfig.SocketMode = socketMode;
      systemd.sockets.pipewire.socketConfig.SocketGroup = socketGroup;

      systemd.user.services.pipewire-system-bridge = {
        description = "Bridge user PipeWire socket to system daemon";
        wantedBy = [ "default.target" ];
        after = [ "basic.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.bash}/bin/bash -c 'mkdir -p %t && ln -sf ${pipewireRuntimeDir}/pipewire-0 %t/pipewire-0 && ln -sf ${pipewireRuntimeDir}/pipewire-0-manager %t/pipewire-0-manager'";
        };
      };

      environment.etc."profile.d/pipewire-system.sh".text = ''
        # Use system-wide PipeWire
        export PIPEWIRE_RUNTIME_DIR=${pipewireRuntimeDir}
      '';

      systemd.sockets.pipewire-pulse.socketConfig.SocketMode = socketMode;
      systemd.sockets.pipewire-pulse.socketConfig.SocketGroup = socketGroup;

      systemd.user.services.pulseaudio-system-bridge = {
        description = "Bridge user PulseAudio socket to system daemon";
        wantedBy = [ "default.target" ];
        after = [ "basic.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.bash}/bin/bash -c 'mkdir -p %t/pulse && ln -sf /run/pulse/native %t/pulse/native'";
        };
      };
    };
}
