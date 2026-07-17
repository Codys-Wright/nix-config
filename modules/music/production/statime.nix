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
        # Announce-receipt-timeout: how many announce intervals statime waits
        # without hearing the grandmaster before it declares the master lost and
        # self-promotes to its (unimplemented, broken) PTPv1 master stub. The
        # default (~3) is twitchy; crank it high as a backstop against the
        # documented startup-race heisenbug (at loglevel=warn statime could hit the
        # timeout and self-promote before processing the leader's first Sync).
        # statime has no real clock and must never be master. NB: in steady state
        # it stays a clean follower regardless — the frequent
        # "got DelayReq, master operation not implemented" warnings are BENIGN
        # multicast noise (Dante PTPv1 multicasts DelayReqs), not self-promotion.
        # null = fork default.
        announceReceiptTimeout ? null,
        # NOTE on RT-core pinning: do NOT add a systemd `CPUAffinity=` directive to
        # this unit. Combined with `CPUSchedulingPolicy=fifo` it fails at boot
        # ("Failed to set up CPU scheduling: Operation not permitted" — e.g. when
        # the targeted cores are still isolcpus-reserved in the running kernel),
        # which crash-loops statime and spams the console so boot looks hung. FIFO
        # 82 unpinned already gives a tight (~100 ns) lock here; if pinning is ever
        # needed, do it best-effort at RUNTIME (chrt/taskset with `|| true`).
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
                  statimePkg = pkgs.statime;
                  netaudioPkg = pkgs.netaudio;
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
                    protocol-version = "${protocolVersion}"${
                      lib.optionalString (
                        announceReceiptTimeout != null
                      ) "\nannounce-receipt-timeout = ${toString announceReceiptTimeout}"
                    }
                  '';

                  # statime binds the PTP UDP ports (319/320), which are
                  # privileged (<1024). But its clock is virtual
                  # (virtual-system-clock = true, hardware-clock = "none"), so
                  # it needs NO CAP_SYS_TIME and NO PTP-hardware-clock device
                  # access — only the port bind. Grant exactly that one
                  # capability via a setcap wrapper so statime can run as a
                  # plain user service (the whole Dante stack is now per-user).
                  security.wrappers.statime = {
                    source = "${statimePkg}/bin/statime";
                    capabilities = "cap_net_bind_service+ep";
                    owner = "root";
                    group = "root";
                  };

                  systemd.user.services = {
                    statime-inferno = {
                      description = "Statime PTP daemon for ${host.name} Dante network";
                      # No network-online ordering: this is a user unit started
                      # via `dante on` well after login, by which time the Dante
                      # static IP has long been up (boot-time assignment).
                      # Gated behind the user dante.target (`dante on|off`):
                      # with the Dante network absent the whole AoIP stack stays
                      # down so a clockless Inferno can't wedge PipeWire.
                      partOf = [ "dante.target" ];
                      wantedBy = [ "dante.target" ];
                      serviceConfig = {
                        Type = "simple";
                        # A crashed statime leaves its usrvclock server socket
                        # behind (/tmp/ptp-usrvclock); the next bind then fails
                        # with EADDRINUSE and the service restart-loops. Remove
                        # it before (re)binding. The `-` ignores failure — e.g. a
                        # stale *root*-owned socket from a prior system-wide run
                        # (cody can't rm that, but /tmp is tmpfs so a reboot
                        # clears it anyway).
                        ExecStartPre = "-${pkgs.coreutils}/bin/rm -f /tmp/ptp-usrvclock";
                        ExecStart = "/run/wrappers/bin/statime --config ${configPath}";
                        Restart = "always";
                        RestartSec = "3s";
                        # statime uses SOFTWARE timestamping (hardware-clock =
                        # "none"), so its virtual-clock servo can only build a
                        # stable frequency estimate if its sync/delay timestamp
                        # captures aren't preempted. Under SCHED_OTHER the PTPv1
                        # offset free-runs at the raw-monotonic drift (~12 ppm)
                        # in a 1 ms sawtooth and never frequency-locks; the
                        # Kalman filter perpetually rejects the jittered
                        # measurements. Run it SCHED_FIFO just ABOVE the Inferno
                        # flow threads (TX 81 / RX 80) so those can't preempt a
                        # capture, but BELOW the hard-RT PipeWire data-loop (88)
                        # so audio is never starved. statime's duty cycle is
                        # tiny (a few µs every ~250 ms), so it doesn't disturb
                        # the flows. cody's RTPRIO rlimit is 95, so the user
                        # manager can grant this. Set in the unit (not via
                        # runtime chrt) so it survives watchdog restarts.
                        CPUSchedulingPolicy = "fifo";
                        CPUSchedulingPriority = 82;
                      };
                    };
                  }
                  // lib.optionalAttrs (preferredLeader != null) {
                    dante-preferred-leader = {
                      description = "Lock ${preferredLeader} as Dante PTP preferred leader";
                      after = [ "statime-inferno.service" ];
                      wants = [ "statime-inferno.service" ];
                      partOf = [ "dante.target" ];
                      wantedBy = [ "dante.target" ];
                      serviceConfig = {
                        # simple, NOT oneshot: the retry loop below can run for
                        # 3 minutes, and a oneshot start job blocks
                        # multi-user.target — which wedges every
                        # nixos-rebuild switch until the loop finishes (and
                        # marks the unit failed if interrupted).
                        Type = "simple";
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
                      partOf = [ "dante.target" ];
                      serviceConfig = {
                        # simple so the up-to-75s recovery loop never holds a
                        # start job open (oneshot start jobs block switches
                        # and go "failed" when interrupted).
                        Type = "simple";
                        ExecStart = pkgs.writeShellScript "statime-watchdog" ''
                          jctl=${pkgs.systemd}/bin/journalctl
                          sctl=${pkgs.systemd}/bin/systemctl
                          # Statime emits "Measurement:" (~4/sec) only while
                          # locked as a PTP follower. Zero in the last 35s means
                          # it self-promoted to its unimplemented PTPv1 master
                          # stub (the heisenbug, or a lost grandmaster).
                          if [ "$("$jctl" --user -u statime-inferno.service --since '35 seconds ago' -o cat | grep -c 'Measurement:')" -gt 0 ]; then
                            exit 0
                          fi
                          echo "Statime not locked; restarting statime-inferno."
                          "$sctl" --user restart statime-inferno.service || true
                          relocked=0
                          for i in $(seq 1 20); do
                            sleep 2
                            if [ "$("$jctl" --user -u statime-inferno.service --since '5 seconds ago' -o cat | grep -c 'Measurement:')" -gt 0 ]; then
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
                              svc: ''"$sctl" --user restart ${svc} || true''
                            ) reinitOnRecovery}
                          fi
                        '';
                      };
                    };
                  };

                  # Timers ride dante.target too — with the stack off they
                  # must not fire (the watchdog would endlessly restart
                  # statime, the leader lock would spam an absent device).
                  systemd.user.timers =
                    lib.optionalAttrs (preferredLeader != null) {
                      dante-preferred-leader = {
                        partOf = [ "dante.target" ];
                        wantedBy = [ "dante.target" ];
                        timerConfig = {
                          OnBootSec = "3min";
                          OnUnitActiveSec = "10min";
                        };
                      };
                    }
                    // lib.optionalAttrs watchdogEnabled {
                      statime-watchdog = {
                        partOf = [ "dante.target" ];
                        wantedBy = [ "dante.target" ];
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
