# THEBATTLESHIP: graphical target reached, no SDDM greeter

**Status:** Both bugs fixed declaratively (2026-08-19); pending a reboot to verify on the live system
**Last verified:** 2026-08-19

## Summary

After boot on 2026-08-19 the machine reached `Reached Target Graphical Interface`
but never showed SDDM or Plasma. The screen stayed dark while the system was
otherwise fully healthy and reachable over Tailscale/SSH.

This was **not** a boot loop and **not** a GPU driver fault. Two independent
problems were found:

1. **SDDM deadlocks when its last DRM output disappears.** The greeter exits
   cleanly, SDDM misreads that clean exit as a successful login handoff, and
   then waits forever for a session that will never start.
2. **`statime-inferno.service` restart-loops inside SDDM's own user session**,
   failing `SETSCHEDULER` every 3 seconds because the `sddm` user has no
   realtime scheduling privilege. This was the bulk of a load average of ~13 on
   an otherwise idle machine.

Only problem 1 caused the dark screen. Problem 2 is a long-standing CPU burn
that is visible on every boot.

## Environment

- NixOS, kernel `6.18.36` `#1-NixOS SMP PREEMPT_RT`
- GPU: NVIDIA GeForce RTX 4080, driver `610.43.02` (`card1`, `0000:01:00.0`)
- Secondary: `amdgpu` iGPU (`card2`, `0000:7a:00.0`)
- Display: single monitor on `card1-DP-3`, 2560x1440
- Generation: `nixos-system-THEBATTLESHIP-26.11.20260623.89570f2`

## Problem 1 — SDDM greeter deadlock on output loss

### Timeline

| Time | Event |
| --- | --- |
| 13:43:19 | `display-manager.service` starts, greeter launches |
| 13:43:21 | Greeter has a real output: `Adding view for "DP-3" QRect(0,0 2560x1440)` |
| 13:44:47 | `There are no outputs - creating placeholder screen` |
| 13:44:47 | `Adding view for "" QRect(0,0 0x0)` |
| 13:44:47 | `wayland greeter finished 0 QProcess::NormalExit` |
| 13:44:47 | `Stopping... kwin-6.7.0/bin/kwin_wayland` |
| 13:44:48 | `wayland compositor finished 15 QProcess::NormalExit` |
| 13:44:48 | `Greeter stopped. SDDM::Auth::HELPER_SUCCESS` |
| 13:44:48 → 13:49:33 | **Nothing.** No greeter, no session, no error. |

### Mechanism

The DP-3 connector dropped out from under the running greeter. With zero
outputs, `kwin_wayland` had nothing to composite on and exited — cleanly, with
status 0. SDDM interpreted that clean greeter exit as
`SDDM::Auth::HELPER_SUCCESS`, i.e. "the greeter handed off to a user session",
and moved into its wait-for-session state. No session ever appeared, and SDDM
never re-probed DRM when the connector came back.

### Why this is hard to spot

- `systemctl --failed` listed **0 units**.
- `display-manager.service` was `active (running)` the entire time, with a live
  `sddm` main PID.
- No unit ever entered a failed state, so nothing in systemd's own view was wrong.

The evidence only exists in the greeter's log lines, not in unit state.

### Ruled out

- **GPU/driver:** `nvidia-smi` clean, zero `Xid` errors in `dmesg`,
  `nvidia_drm modeset=Y`, `fbdev=Y`. The driver never faulted.
- **Connector genuinely dead:** at diagnosis time
  `/sys/class/drm/card1-DP-3/status` read `connected` with `2560x1440` modes
  listed. The output had already returned; SDDM simply never noticed.

The trigger for the connector dropping was not captured — most likely monitor
DPMS/power-save, an input switch on the display, or a DP link retrain. Nothing
in the kernel log marks it.

### Fix applied

```
sudo systemctl restart display-manager.service
```

Greeter came back immediately with a real output:
`Adding view for "DP-3" QRect(0,0 2560x1440)`.

### Durable fix applied

`modules/desktop/display-manager/sddm-output-watchdog.nix` — a new aspect,
included automatically by `<fleet.desktop.display-manager/sddm>`.

A udev rule on DRM hotplug events pulls in a oneshot
`sddm-output-watchdog.service`:

```
ACTION=="change", SUBSYSTEM=="drm", ENV{HOTPLUG}=="1", TAG+="systemd", \
  ENV{SYSTEMD_WANTS}+="sddm-output-watchdog.service"
```

The service restarts `display-manager.service` **only** when all three hold:

1. `display-manager.service` is active,
2. no `sddm-greeter` process is running, and
3. no session on `seat0` has `Class=user`.

That combination is exactly the wedge, so an ordinary hotplug (greeter alive)
and a hotplug during a live desktop session (user session present) both no-op.
`StartLimitIntervalSec=5min` / `StartLimitBurst=3` keep a hotplug storm from
turning into a DM restart loop.

Note that `Restart=` on `display-manager.service` does **not** help here: the
service never exits, it wedges while still `active (running)` — which is why
this had to be an external prod rather than a unit-level restart policy.

Relevant config:
- `modules/desktop/display-manager/sddm-output-watchdog.nix`
- `modules/desktop/display-manager/sddm.nix`

## Problem 2 — `statime-inferno.service` SETSCHEDULER restart loop

### Symptom

```
statime-inferno.service: Scheduled restart job, restart counter is at 22.
(statime)[7737]: statime-inferno.service: Failed to set up CPU scheduling: Operation not permitted
(statime)[7737]: statime-inferno.service: Failed at step SETSCHEDULER spawning /run/wrappers/bin/statime: Operation not permitted
statime-inferno.service: Main process exited, code=exited, status=214/SETSCHEDULER
statime-inferno.service: Failed with result 'exit-code'.
```

**93** `SETSCHEDULER` failures in a single boot. Restart counter reached 23 before
rolling over, cycling roughly every 3 seconds, continuously.

### Root cause

`statime-inferno` is defined as a **user** service
(`modules/music/production/statime.nix:120`, `systemd.user.services`) with:

- `Restart = "always"` (line 142)
- `RestartSec = "3s"` (line 143)
- `CPUSchedulingPolicy = "fifo"` (line 159)
- `CPUSchedulingPriority = 82` (line 160)

The in-file comment states the assumption directly: *"cody's RTPRIO rlimit is 95,
so the user…"*. That assumption holds for `cody` — and only for `cody`.

Because it is a user unit gated behind the user `dante.target`, systemd
instantiates it in **every** user manager that reaches that target, including
the one SDDM runs for its own `sddm` user. Group membership is the deciding
factor:

```
id sddm  → uid=175(sddm) gid=175(sddm) groups=175(sddm)
id cody  → ... 17(audio) ... 323(pipewire) ...
```

`sddm` is in neither `@audio` nor `@pipewire`, so `pam_limits` never grants it
`RLIMIT_RTPRIO`. `CPUSchedulingPolicy=fifo` at priority 82 therefore fails with
`EPERM`, systemd reports `214/SETSCHEDULER`, `Restart=always` fires 3 seconds
later, and the cycle repeats for as long as a greeter session exists.

Verified on the live system — `cody`'s user manager (pid 19195):

```
Max realtime priority     95    95
```

### Fix applied

`ConditionUser=cody` now gates **every** unit in the Dante/AoIP stack, not just
`statime-inferno` — THEBATTLESHIP has five declared users (`cody`, `joshua`,
`guest`, `bri`, `carter`) plus `sddm`, and `dante.target` is
`wantedBy = default.target`, so the whole stack was being instantiated six
times over.

`fleet.music._.production._.statime` and `…._.inferno` each gained a `user`
parameter (default `null` = ungated, preserving the old behaviour for any other
host); THEBATTLESHIP passes `user = "cody"`. In `statime.nix` a small `gate`
helper stamps the condition onto each unit via `lib.mapAttrs`, so new units in
that module inherit it automatically.

Verified in the built system closure — all nine user units carry it:

```
statime-inferno.service          ConditionUser=cody StartLimitBurst=5 StartLimitIntervalSec=60s
dante.target                     ConditionUser=cody
inferno-nodes.service            ConditionUser=cody
studio-clock-ready.service       ConditionUser=cody
pipewire-watchdog.service        ConditionUser=cody
statime-watchdog.service         ConditionUser=cody
dante-preferred-leader.service   ConditionUser=cody
statime-watchdog.timer           ConditionUser=cody
dante-preferred-leader.timer     ConditionUser=cody
```

`statime-inferno` additionally got `StartLimitIntervalSec=60s` /
`StartLimitBurst=5` unconditionally, so even inside cody's own manager an
unexpected `EPERM` or crash becomes a bounded give-up rather than an infinite
3-second loop.

Note that `ConditionUser` on `dante.target` alone would not have been enough:
a skipped condition does not stop systemd from starting the units the target
`Wants`. Each unit has to carry it.

Relevant config:
- `modules/music/production/statime.nix`
- `modules/music/production/inferno.nix`
- `hosts/THEBATTLESHIP/THEBATTLESHIP.nix` (the `user = "cody"` call-site args)
- `hosts/THEBATTLESHIP/studio-routing.nix`
- `modules/hardware/audio/pipewire/pipewire.nix:130` (`security.pam.loginLimits`)

## Other findings (not investigated further)

### statime is stepping the clock by ~56 years

```
Intermediate interclock measurement: diff 1787172184191142932.5 delay 180.5
Measurement too far from state, resetting
Stepped clock by -1787172184.1911433s
```

`1.787e9` seconds ≈ 56 years. The PTP source is handing statime nonsense and the
Kalman filter is resetting to it rather than rejecting it.

### PipeWire cannot reach the Dante hardware

```
spa.alsa: set_hw_params: Connection timed out
pw.node: (Inferno sink-35) suspended -> error (Start error: Connection timed out)
```

Recurs on every session start. Likely the same underlying Dante/AES67 network
problem as the clock issue above.

### polkit admin rules are broken

```
polkitd[2387]: Error evaluating admin rules: ReferenceError: identifier 'org' undefined
```

A JS syntax/reference error in a polkit rules file is breaking admin-rule
evaluation system-wide. Worth tracking down separately.

### Minor

- `tmux.service: Failed with result 'exit-code'` on session start.
- `tmux.service:12: Unit uses KillMode=none` — deprecated, slated for removal.
- `/home/cody/.config/autostart/stylix-activate-gnome.desktop`: stat() failed,
  file does not exist (stale autostart entry).
- `studio-routing-links.service` and `studio-clock-ready.service` exit with
  `15/TERM` on session teardown; this appears to be normal shutdown, not a fault.

## Methodology notes

Two false leads are worth recording, since both are easy to repeat.

**The "session loop" was self-inflicted.** A user-level `systemd` at 81% CPU with
a rapidly incrementing PID looked exactly like a session crash-loop
(`systemd[9754]` → `[10859]` → `[12012]`). Those were sessions created by the
diagnosing SSH commands themselves — each `ssh` opens a PAM session whose user
manager lingers ~10 seconds after disconnect. When debugging a machine remotely,
your own tooling appears in the evidence.

**`sudo -u sddm bash -c 'ulimit -r'` reports 95 and is misleading.** `sudo`
inherits the calling process's rlimits rather than re-applying `limits.conf` for
the target user, so it reports `cody`'s limit, not `sddm`'s. Group membership
(`id sddm`) and `/proc/<pid>/limits` on an actual user-manager process are the
reliable checks.

## Quick reference

```
# Is the DM wedged? (active but no greeter since the last "Greeter stopped")
systemctl status display-manager.service
journalctl -b -u display-manager | tail -20

# Does the connector actually have a monitor on it?
cat /sys/class/drm/card1-DP-3/status
cat /sys/class/drm/card1-DP-3/modes

# GPU sanity
nvidia-smi
sudo dmesg | grep -iE 'nvidia|nvrm|xid'

# The statime loop
sudo journalctl -b | grep -c SETSCHEDULER

# Recover the login screen
sudo systemctl restart display-manager.service
```
