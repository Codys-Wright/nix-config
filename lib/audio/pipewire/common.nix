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

  mkLoopbackModule =
    {
      description,
      captureProps,
      playbackProps,
      nodeName ? null,
    }:
    {
      name = "libpipewire-module-loopback";
      args = lib.filterAttrs (_: v: v != null) {
        inherit description nodeName;
        capture.props = captureProps;
        playback.props = playbackProps;
      };
    };

  mkRouteRule =
    {
      matches,
      targetObject,
    }:
    {
      inherit matches;
      actions.update-props = {
        target.object = targetObject;
      };
    };
in
{
  inherit
    mkChannelPositions
    mkPositionString
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
      loopbackModules = map mkLoopbackModule loopbacks;
      routeRules = map mkRouteRule routes;
      defaultConfig = lib.optionalAttrs (defaultSink != null || defaultSource != null) {
        "wireplumber.settings" = lib.filterAttrs (_: v: v != null) {
          "default.configured.audio.sink" = defaultSink;
          "default.configured.audio.source" = defaultSource;
        };
      };
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

            "93-studio-buses" = {
              context.modules = loopbackModules;
            };
          }
          // extraPipewireConfig;

          pipewire-pulse = {
            "92-low-latency" = {
              context.modules = [
                {
                  name = "libpipewire-module-protocol-pulse";
                  args = {
                    pulse.min.req = pulseMinReq;
                    pulse.default.req = pulseDefaultReq;
                    pulse.max.req = pulseMaxReq;
                    pulse.min.quantum = pulseMinQuantum;
                    pulse.max.quantum = pulseMaxQuantum;
                  };
                }
              ];
              stream.properties = {
                node.latency = pulseDefaultReq;
                resample.quality = resampleQuality;
              };
            };

            "93-studio-routing" = lib.optionalAttrs (routes != [ ]) {
              stream.rules = routeRules;
            };
          }
          // extraPulseConfig;
        };
      };

      services.pipewire.wireplumber.extraConfig."51-studio-defaults" =
        defaultConfig // extraWireplumberConfig;

      environment.systemPackages = systemPackages pkgs;

      systemd.services.pipewire.serviceConfig.Environment = [
        "ALSA_PLUGIN_DIR=${alsaPluginDir}"
      ];
      systemd.services.pipewire.serviceConfig.SystemCallFilter = [ "@clock" ];

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

      systemd.services.pipewire-pulse = {
        wantedBy = [ "multi-user.target" ];
        serviceConfig.Environment = [
          "PIPEWIRE_RUNTIME_DIR=${pipewireRuntimeDir}"
          "ALSA_PLUGIN_DIR=${alsaPluginDir}"
        ];
      };

      systemd.services.wireplumber = {
        wantedBy = [ "multi-user.target" ];
        serviceConfig.Environment = [
          "PIPEWIRE_RUNTIME_DIR=${pipewireRuntimeDir}"
        ];
      };

      systemd.sockets.pipewire-pulse.socketConfig.SocketMode = socketMode;
      systemd.sockets.pipewire-pulse.socketConfig.SocketGroup = socketGroup;

      systemd.user.services.pulseaudio-system-bridge = {
        description = "Bridge user PulseAudio socket to system daemon";
        wantedBy = [ "default.target" ];
        after = [ "basic.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.bash}/bin/bash -c 'mkdir -p %t/pulse && ln -sf ${pipewireRuntimeDir}/pulse/native %t/pulse/native'";
        };
      };
    };
}
