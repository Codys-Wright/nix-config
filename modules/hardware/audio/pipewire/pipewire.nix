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
{
  den,
  inputs,
  lib,
  ...
}:
{
  # PipeWire tracks current nixos-unstable via a dedicated input instead of
  # riding the (older) main nixpkgs pin: the 2026-07 nixpkgs update regressed
  # PipeWire 1.6.5 → 1.6.3, whose ALSA-plugin handling breaks Inferno's Dante
  # bridge (plugin probes then closes; DeviceServer never comes up). Only the
  # daemon-side stack (pipewire + wireplumber) comes from this input — client
  # libs elsewhere keep the main pin (native protocol is stable across 1.x).
  # `just update` bumps this to the latest cached unstable PipeWire.
  flake-file.inputs.nixpkgs-pipewire.url = lib.mkDefault "github:nixos/nixpkgs/nixos-unstable";

  fleet.hardware._.audio._.pipewire = {
    description = "PipeWire audio system (system-wide, low-latency)";

    __functor =
      _self:
      {
        defaultSink ? null,
        defaultSource ? null,
        stickyNodes ? [ ],
        lingerUsers ? [ ],
        # System-wide PipeWire (runs as the `pipewire` user at boot, before
        # login). Discouraged upstream — it disables session-dependent
        # features like the xdg-desktop-portal Camera/permission-store path.
        # Default per-user; only set true on hosts that genuinely need audio
        # before any user logs in (and accept the broken camera portal).
        systemWide ? false,
        clockRate ? 48000,
        # 1024 is the safe default — high idle latency keeps Inferno/Dante TX
        # timing stable on THEBATTLESHIP. Apps that need low latency (REAPER,
        # OBS) pull it down via force-quantum; `pw-buffer 128` works live too.
        clockQuantum ? 1024,
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
                    // (lib.optionalAttrs systemWide {
                      # The `pipewire` system user only exists when running
                      # system-wide; referencing it per-user is an eval error.
                      pipewire.extraGroups = [ "audio" ];
                    });
                };
            }
          )
          (
            { host, ... }:
            let
              selectedLingerUsers = builtins.filter (userName: builtins.hasAttr userName host.users) lingerUsers;
            in
            {
              nixos.users.users = builtins.listToAttrs (
                map (userName: {
                  name = userName;
                  value.linger = true;
                }) selectedLingerUsers
              );
            }
          )
        ];

        nixos =
          { pkgs, lib, ... }:
          let
            pkgsPipewire = import inputs.nixpkgs-pipewire {
              system = pkgs.stdenv.hostPlatform.system;
              config.allowUnfree = true;
            };
          in
          {
            security.rtkit.enable = true;

            # nixpkgs' services.pipewire module adds a default
            #   @pipewire memlock 4194304   (= 4 GiB)
            # PAM applies the last matching limits.conf line, so for users
            # in BOTH @audio and @pipewire (cody) this clamps RLIMIT_MEMLOCK
            # at 4 GiB even though musnix's @audio entry is `unlimited`.
            # With 192 GiB of RAM that's pointlessly tight for large sample
            # libraries pinned via mlock(). Re-state @pipewire memlock as
            # unlimited so the audio path wins regardless of group order.
            security.pam.loginLimits = [
              {
                domain = "@pipewire";
                item = "memlock";
                type = "-";
                value = "unlimited";
              }
            ];

            services.pipewire = {
              enable = true;
              # Daemon + session manager from the dedicated nixpkgs-pipewire
              # input (see header) — keeps PipeWire at current upstream while
              # the rest of the system stays on the main nixpkgs pin.
              package = lib.mkDefault pkgsPipewire.pipewire;
              wireplumber.package = lib.mkDefault pkgsPipewire.wireplumber;
              inherit systemWide;
              # Eager start when system-wide (no session to socket-activate
              # against); socket-activate in the normal per-user case.
              socketActivation = !systemWide;

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
            systemd.sockets.pipewire.wantedBy = lib.mkIf systemWide [ "sockets.target" ];
            systemd.services.pipewire.wantedBy = lib.mkIf systemWide [ "multi-user.target" ];
            # Same fix for the PulseAudio bridge — without this, /run/pulse/native
            # never appears and KDE Plasma's plasma-pa client sits forever in
            # "connecting to sound server", and volume keys do nothing. Socket
            # activation is enough; the service starts on first connect.
            systemd.sockets.pipewire-pulse.wantedBy = lib.mkIf systemWide [ "sockets.target" ];

            # Per-user PipeWire's upstream systemd.user.services.pipewire unit
            # already carries the RT rlimits / NOFILE, and rtkit + PAM grant
            # SCHED_FIFO to a real login session — so this manual system-service
            # tuning is only needed (and only valid) in the system-wide case.
            systemd.services.pipewire.serviceConfig = lib.mkIf systemWide {
              Environment = [ "ALSA_PLUGIN_DIR=/run/current-system/sw/lib/alsa-lib" ];
              SystemCallFilter = [
                "@system-service"
                "@clock"
                # SCHED_FIFO / SCHED_RR / sched_setaffinity for the DSP graph.
                "@resources"
              ];
              # Each link allocates a few file descriptors (event fds, shm
              # segments). With ~150+ static link-factory pins a 128-ch
              # Inferno graph trips the systemd default 1024/4096 limit and
              # PipeWire logs `error alloc buffers: Too many open files`.
              # 524288 is the upstream-recommended ceiling.
              LimitNOFILE = 524288;
              # systemWide PipeWire runs as the `pipewire` system user with
              # no PAM session, so neither rtkit nor security.pam.loginLimits
              # ever grant SCHED_FIFO to the daemon's DSP threads. The
              # symptom downstream is JACK/Reaper clients logging
              # `jack: non-realtime threads` because the graph they connect
              # to is itself SCHED_OTHER. Pin the rlimits on the unit
              # directly and hand it CAP_SYS_NICE so module-rt can promote.
              LimitRTPRIO = 95;
              LimitMEMLOCK = "infinity";
              LimitNICE = -19;
              IOSchedulingClass = "realtime";
              IOSchedulingPriority = 4;
              AmbientCapabilities = [
                "CAP_SYS_NICE"
                "CAP_IPC_LOCK"
              ];
              CapabilityBoundingSet = [
                "CAP_SYS_NICE"
                "CAP_IPC_LOCK"
              ];
            };

            # PipeWire's rt.time.soft default is 5_000_000 µs. RTKit's
            # default rttime-usec-max is 200_000 µs, so any client asking
            # for SCHED_FIFO via the RTKit path (Reaper's bundled libjack
            # fallback, Flatpak apps, etc.) gets denied with EPERM. Lift
            # the cap so RTKit can honour the request.
            systemd.services.rtkit-daemon.serviceConfig.ExecStart = [
              ""
              "${pkgs.rtkit}/libexec/rtkit-daemon --rttime-usec-max=2000000"
            ];

            # Only needed to expose the system-wide sockets to the user
            # session. Per-user PipeWire owns $XDG_RUNTIME_DIR natively.
            systemd.user.services.pipewire-system-bridge = lib.mkIf systemWide {
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
              # Runtime buffer-size switcher. `pw-buffer` with no args prints
              # the current quantum/rate; `pw-buffer 64|128|256|512|1024`
              # forces a new quantum without restarting PipeWire or Reaper.
              # `pw-buffer reset` clears force-quantum and returns to the
              # Nix-configured default. Quantum is in frames; latency in ms
              # is roughly quantum / rate * 1000 (e.g. 128 @ 48 kHz = 2.67).
              (writeShellScriptBin "pw-buffer" ''
                set -euo pipefail
                pw_meta="${pkgs.pipewire}/bin/pw-metadata"
                case "''${1:-}" in
                  "")
                    echo "current settings:"
                    "$pw_meta" -n settings 0 | grep -E 'clock\.(rate|quantum|force-)' || true
                    echo
                    echo "usage: pw-buffer <frames|reset>"
                    echo "  frames: 32 64 128 256 512 1024 2048"
                    echo "  reset : clear force-quantum, return to default (${toString clockQuantum})"
                    ;;
                  reset)
                    "$pw_meta" -n settings 0 clock.force-quantum 0
                    echo "force-quantum cleared"
                    ;;
                  *[!0-9]*|"")
                    echo "error: invalid argument '$1'" >&2
                    exit 1
                    ;;
                  *)
                    q=$1
                    "$pw_meta" -n settings 0 clock.force-quantum "$q"
                    rate=$("$pw_meta" -n settings 0 | awk -F"'" '/clock.rate/{print $4; exit}')
                    : "''${rate:=${toString clockRate}}"
                    awk -v q="$q" -v r="$rate" 'BEGIN{printf "quantum=%d rate=%d  ~%.2f ms\n", q, r, q/r*1000}'
                    ;;
                esac
              '')
            ];
          };
      };
  };
}
