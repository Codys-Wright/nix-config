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
#       "alsa_output.pci-0000_01_00.1.hdmi-stereo-extra1"
#     ];
#   })
#
# When called with no args (the default via the audio facet), you get a plain
# low-latency PipeWire setup. Hosts that need studio routing should configure
# them in their own aspect on top of this.
{ den, ... }:
{
  fleet.hardware._.audio._.pipewire = {
    description = "PipeWire audio system (system-wide, low-latency)";

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
            let
              audioGroups = [
                "audio"
                "pipewire"
              ];
            in
            {
              nixos =
                { lib, ... }:
                {
                  users.users =
                    (lib.listToAttrs (
                      map (userName: {
                        name = userName;
                        value = {
                          extraGroups = audioGroups;
                        };
                      }) (builtins.attrNames host.users)
                    ))
                    // {
                      pipewire.extraGroups = [ "audio" ];
                    };
                };
            }
          )
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

            # nixpkgs only wires pipewire into sockets.target when socketActivation
            # is true. With socketActivation = false we get an orphaned linked unit
            # that never starts. Wire both explicitly: socket into sockets.target so
            # the upstream Requires=pipewire.socket in pipewire.service is satisfied,
            # and the service into multi-user.target for eager boot-time startup.
            systemd.sockets.pipewire.wantedBy = [ "sockets.target" ];
            systemd.services.pipewire.wantedBy = [ "multi-user.target" ];

            systemd.services.pipewire.serviceConfig = {
              Environment = [ "ALSA_PLUGIN_DIR=/run/current-system/sw/lib/alsa-lib" ];
              SystemCallFilter = [
                "@system-service"
                "@clock"
              ];
              # Each link allocates a few file descriptors (event fds, shm
              # segments). With ~150+ static link-factory pins a 128-ch
              # Inferno graph trips the systemd default 1024/4096 limit and
              # PipeWire logs `error alloc buffers: Too many open files`.
              # 524288 is the upstream-recommended ceiling.
              LimitNOFILE = 524288;
            };

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
                  systemctl --user set-environment "PULSE_SERVER=$XDG_RUNTIME_DIR/pulse/native"
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
