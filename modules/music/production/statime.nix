# Statime PTP daemon for Inferno / Dante clock sync.
#
# Parametric — each host supplies its Dante NIC and (optionally) the Dante
# device it wants locked as preferred PTP leader.
#
#   (fleet.music._.production._.statime {
#     interface  = "enp12s0";
#     # Optional: lock a specific device as Dante PTP leader
#     preferredLeader = "AA-4202524000109";
#   })
#
# The Dante interface lives on the host, so we take it as a parameter rather
# than trying to auto-detect it. The host's name is used for service
# descriptions so multiple hosts in a fleet can be told apart in journalctl.
{ fleet, lib, ... }:
{
  fleet.music._.production._.statime = {
    description = "Statime PTP daemon (Inferno fork) for Dante clock sync";

    __functor =
      _self:
      {
        interface,
        preferredLeader ? null,
        loglevel ? "warn",
        sdoId ? 0,
        domain ? 0,
        priority1 ? 251,
        protocolVersion ? "PTPv1",
        # Self-heal: restart statime whenever it loses PTP lock. Requires a
        # loglevel that emits "Measurement:" lines (debug/info/trace) — the
        # signal the watchdog uses to tell "locked follower" from "stuck master".
        watchdog ? true,
        # Services to restart after the watchdog recovers a lost lock. The
        # Inferno PipeWire node must be re-opened against a valid clock, so the
        # host passes its session manager here (e.g. [ "wireplumber.service" ]).
        reinitOnRecovery ? [ ],
        ...
      }:
      {
        includes = [
          (
            { host, ... }:
            {
              nixos =
                { pkgs, lib, ... }:
                let
                  statimePkg = pkgs.callPackage ../../../packages/statime/statime.nix { };
                  netaudioPkg = pkgs.callPackage ../../../packages/netaudio/netaudio.nix { };
                  configPath = "/etc/inferno/statime-ptpv1.toml";
                  # The watchdog's lock signal ("Measurement:") is only logged
                  # at info/debug/trace, so disable it on quieter loglevels.
                  watchdogEnabled =
                    watchdog
                    && builtins.elem loglevel [
                      "trace"
                      "debug"
                      "info"
                    ];
                in
                {
                  environment.systemPackages = [
                    statimePkg
                    netaudioPkg
                  ];

                  environment.etc."inferno/statime-ptpv1.toml".text = ''
                    loglevel = "${loglevel}"
                    sdo-id = ${toString sdoId}
                    domain = ${toString domain}
                    priority1 = ${toString priority1}
                    virtual-system-clock = true
                    virtual-system-clock-base = "monotonic_raw"
                    usrvclock-export = true

                    [[port]]
                    interface = "${interface}"
                    network-mode = "ipv4"
                    hardware-clock = "none"
                    protocol-version = "${protocolVersion}"
                  '';

                  systemd.services = {
                    statime-inferno = {
                      description = "Statime PTP daemon for ${host.name} Dante network";
                      after = [ "network-online.target" ];
                      wants = [ "network-online.target" ];
                      wantedBy = [ "multi-user.target" ];
                      serviceConfig = {
                        Type = "simple";
                        ExecStart = "${statimePkg}/bin/statime --config ${configPath}";
                        Restart = "always";
                        RestartSec = "3s";
                      };
                    };
                  }
                  // lib.optionalAttrs (preferredLeader != null) {
                    dante-preferred-leader = {
                      description = "Lock ${preferredLeader} as Dante PTP preferred leader";
                      after = [ "statime-inferno.service" ];
                      wants = [ "statime-inferno.service" ];
                      wantedBy = [ "multi-user.target" ];
                      serviceConfig = {
                        Type = "oneshot";
                        ExecStart = pkgs.writeShellScript "dante-preferred-leader" ''
                          # Retry until the leader device answers. A Dante device
                          # absent at boot would otherwise never get locked (the
                          # old one-shot skipped silently). The timer re-asserts
                          # periodically so the lock survives the leader rebooting.
                          for i in $(seq 1 18); do
                            if ${netaudioPkg}/bin/netaudio --name ${preferredLeader} device config preferred-leader on; then
                              echo "Locked ${preferredLeader} as Dante PTP preferred leader."
                              exit 0
                            fi
                            echo "Dante leader ${preferredLeader} not reachable (attempt $i); retrying in 10s..."
                            sleep 10
                          done
                          echo "Dante leader ${preferredLeader} still unavailable; timer will retry later."
                        '';
                      };
                    };
                  }
                  // lib.optionalAttrs watchdogEnabled {
                    statime-watchdog = {
                      description = "Restart Statime if it loses PTP lock (self-promotes to broken PTPv1 master)";
                      after = [ "statime-inferno.service" ];
                      serviceConfig = {
                        Type = "oneshot";
                        ExecStart = pkgs.writeShellScript "statime-watchdog" ''
                          jctl=${pkgs.systemd}/bin/journalctl
                          sctl=${pkgs.systemd}/bin/systemctl
                          # Statime emits "Measurement:" (~4/sec) only while
                          # locked as a PTP follower. Zero in the last 35s means
                          # it self-promoted to its unimplemented PTPv1 master
                          # stub (the heisenbug, or a lost grandmaster).
                          if [ "$("$jctl" -u statime-inferno.service --since '35 seconds ago' -o cat | grep -c 'Measurement:')" -gt 0 ]; then
                            exit 0
                          fi
                          echo "Statime not locked; restarting statime-inferno."
                          "$sctl" restart statime-inferno.service
                          relocked=0
                          for i in $(seq 1 20); do
                            sleep 2
                            if [ "$("$jctl" -u statime-inferno.service --since '5 seconds ago' -o cat | grep -c 'Measurement:')" -gt 0 ]; then
                              relocked=1
                              break
                            fi
                          done
                          # Only re-init dependents if the clock actually came
                          # back — otherwise (grandmaster truly gone) we'd churn
                          # the audio session every cycle for nothing.
                          if [ "$relocked" = 1 ]; then
                            echo "Statime re-locked; re-initialising audio session."
                            ${lib.concatMapStringsSep "\n                            " (
                              svc: ''"$sctl" restart ${svc} || true''
                            ) reinitOnRecovery}
                          fi
                        '';
                      };
                    };
                  };

                  systemd.timers =
                    lib.optionalAttrs (preferredLeader != null) {
                      dante-preferred-leader = {
                        wantedBy = [ "timers.target" ];
                        timerConfig = {
                          OnBootSec = "3min";
                          OnUnitActiveSec = "10min";
                        };
                      };
                    }
                    // lib.optionalAttrs watchdogEnabled {
                      statime-watchdog = {
                        wantedBy = [ "timers.target" ];
                        timerConfig = {
                          OnBootSec = "90s";
                          OnUnitActiveSec = "30s";
                        };
                      };
                    };
                };
            }
          )
        ];
      };
  };
}
