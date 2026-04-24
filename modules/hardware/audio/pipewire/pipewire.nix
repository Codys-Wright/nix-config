# PipeWire audio aspect.
#
# System-wide PipeWire so Inferno's ALSA plugin (which needs to run at system
# boot, before any user logs in, because it holds the Dante PCM device open)
# can share the same graph as user applications.
#
# The module is parametric so it can be deployed on multiple hosts:
#
#   (fleet.hardware._.audio._.pipewire {
#     defaultSink = "system_audio";
#     defaultSource = "talkback_mic";
#     stickyNodes = [
#       # node.name patterns that must never suspend
#       "alsa_output.pci-0000_01_00.1.hdmi-stereo-extra1"
#     ];
#   })
#
# When called with no args (the default via the audio facet), you get a plain
# low-latency PipeWire setup with no virtual sinks or routing rules. Hosts that
# need studio routing (virtual sinks, app -> sink rules) should configure them
# in their own aspect on top of this.
{
  den,
  ...
}:
{
  fleet.hardware._.audio._.pipewire = {
    description = "PipeWire audio system (system-wide, low-latency)";

    includes = [
      (den.lib.groups [
        "audio"
        "pipewire"
      ])
    ];

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
            {
              nixos.users.users = builtins.mapAttrs (_: _: { linger = true; }) host.users;
            }
          )
        ];

        nixos =
          { pkgs, lib, ... }:
          {
            security.rtkit.enable = true;

            services.pipewire = {
              enable = true;
              systemWide = true;
              socketActivation = false;

              alsa = {
                enable = true;
                support32Bit = true;
              };
              pulse.enable = true;
              jack.enable = true;
              wireplumber.enable = true;

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

            # PipeWire needs to find the Inferno ALSA plugin. System services
            # don't inherit environment.variables, so set it explicitly.
            systemd.services.pipewire.serviceConfig.Environment = [
              "ALSA_PLUGIN_DIR=/run/current-system/sw/lib/alsa-lib"
            ];

            # Inferno's ALSA plugin needs clock syscalls (clock_nanosleep,
            # clock_adjtime). The NixOS pipewire module sets
            # SystemCallFilter=@system-service which blocks them. We add @clock
            # via a systemd drop-in so the two filter sets are unioned (systemd
            # merges multiple SystemCallFilter lines) rather than overriding.
            environment.etc."systemd/system/pipewire.service.d/allow-clock.conf".text = ''
              [Service]
              SystemCallFilter=@clock
            '';

            # Bridge the system-wide pipewire / pulse sockets into each user's
            # XDG_RUNTIME_DIR so userland apps Just Work without any per-user
            # daemon.
            systemd.user.services.pipewire-system-bridge = {
              description = "Bridge system-wide PipeWire sockets into user runtime dir";
              wantedBy = [ "default.target" ];
              after = [ "basic.target" ];
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
                ExecStart = pkgs.writeShellScript "pipewire-system-bridge" ''
                  set -eu
                  mkdir -p "$XDG_RUNTIME_DIR/pulse"
                  ln -sf /run/pipewire/pipewire-0         "$XDG_RUNTIME_DIR/pipewire-0"
                  ln -sf /run/pipewire/pipewire-0-manager "$XDG_RUNTIME_DIR/pipewire-0-manager"
                  ln -sf /run/pulse/native                "$XDG_RUNTIME_DIR/pulse/native"
                '';
              };
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
