# PipeWire: system-wide → per-user migration (THEBATTLESHIP)

## Why

System-wide PipeWire (`services.pipewire.systemWide = true`) runs WirePlumber
under the `main-systemwide` profile, which **disables the session-dependent
`support.portal-permissionstore`** — the exact plumbing the xdg-desktop-portal
**Camera** path needs. Result: OBS's PipeWire camera source + Discord got an
empty camera list. Per-user PipeWire is the upstream-recommended default and
makes the camera portal work.

The only thing system-wide bought us was **Inferno/Dante at boot before login**.
We traded that away: Dante now comes up at `dante on` (post-login), which is
fine for a single-user workstation.

## What changed (branch `pipewire-per-user`)

- `modules/hardware/audio/pipewire/pipewire.nix`: `systemWide ? false` param;
  all system-wide-only plumbing (custom `pipewire.service` serviceConfig, socket
  `wantedBy` wiring, `pipewire-system-bridge`, the `pipewire` system-user group)
  gated behind it. **All hosts flip to per-user** — only THEBATTLESHIP runs
  Dante, so the others are a strict improvement.
- `modules/music/production/statime.nix`: statime's clock is virtual
  (`virtual-system-clock`, `hardware-clock = none`) so it needs **only** the PTP
  UDP 319/320 bind — granted via a `security.wrappers` setcap
  (`cap_net_bind_service+ep`). So statime runs as a **user** service and the
  whole Dante stack is per-user (no system/user split, watchdog restarts
  wireplumber same-manager via `--user`). Plus an `ExecStartPre` that removes a
  stale `/tmp/ptp-usrvclock` so a crash can't re-block the bind.
- `modules/music/production/inferno.nix` + `hosts/THEBATTLESHIP/THEBATTLESHIP.nix`:
  inferno-nodes, dante.target, studio-{local,routing}-links, studio-clock-ready,
  daw-router, pipewire-watchdog(+timer), and the wireplumber seed-profiles
  ExecStartPre all converted to `systemd.user.*` (drop `User=pipewire`,
  `/run/pipewire`, `multi-user.target`→`default.target`, `systemctl --user`,
  wireplumber state under `~/.local/state`). `dante` toggle uses
  `systemctl --user`. libcamera monitor disabled on the `main` profile.

## Post-reboot verification checklist

Reboot first (clears system-wide-era `/tmp` leftovers; brings the user stack up
clean). Make sure the **Dante preferred leader is powered on** before `dante on`.

1. `systemctl --user status pipewire wireplumber pipewire-pulse` → active as cody.
2. `wpctl status` (no sudo) → default sink `system_audio`; sinks `games`,
   `voice_chat`, `daw` present; one v4l2 node per camera (no libcamera dupes).
3. Play audio with **Dante off** → heard on the TF (studio-local-links fanout).
4. `dante on`, then `journalctl --user -u statime-inferno -f` → **`Measurement:`**
   lines = PTP locked. Then Inferno sink/source nodes appear; `studio-clock-ready`
   bounces wireplumber once; Dante audio flows.
5. REAPER → lands on `daw`, no `jack: non-realtime threads` (RT via rtkit/PAM).
6. **The goal:** OBS PipeWire camera source + Discord → cameras populate & share.

## Known gotchas / one-time fixes already applied at runtime

- **Stale `default-nodes`**: cody's old per-user state pinned the default sink to
  a phantom `Yamaha_TF...multichannel-output`. Reset → `system_audio` (persisted).
- **`/tmp/ptp-usrvclock` root-owned leftover** from the system-wide statime
  blocked the user statime's bind (`EADDRINUSE`). Removed; reboot prevents
  recurrence (tmpfs), and the new `ExecStartPre` handles crash-time staleness.

## Rollback

`main` (commit before the branch) is the full working system-wide config:
`sudo nixos-rebuild switch --rollback`, or `git checkout main && just switch`.

## Follow-ups (candidates once verified)

- Trim watchdog/clock-ready band-aids that existed to work around system-wide
  wedging — per-user may make some unnecessary.
- Confirm statime PTP **lock** is stable across reboots (it's historically
  finicky — needs exactly one grandmaster; see `docs/thebattleship-audio.md`).
