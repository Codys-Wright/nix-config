# Inferno on THEBATTLESHIP

**Status:** Resolved and consolidated
**Last verified:** 2026-04-21

## Summary

The current Inferno setup is declarative, system-wide, and lives in the flake. The previous duplicate asound.conf and legacy helper-script problems have been removed.

## Current source of truth

- `modules/music/production/inferno.nix`
- `modules/music/production/statime.nix`
- `modules/hardware/audio/pipewire/pipewire.nix`
- `hosts/THEBATTLESHIP/THEBATTLESHIP.nix`

## Current live behavior

- System-wide PipeWire is enabled
- Inferno sink/source services are active
- `statime-inferno` is active
- `systemd-timesyncd` is disabled
- THEBATTLESHIP is advertised on Dante
- The live profile is currently 16x16 channels

## What changed

- Removed duplicate Inferno include from the older user config path
- Removed dependence on upstream helper-script wrappers
- Kept the ALSA config authoritative in `/etc/asound.conf`
- Kept PipeWire clock syscalls explicitly allowed

## Notes

- Historical reports of 44,700,000 ms latency were symptoms of the old duplicate or mismatched setup
- If the reported latency drifts again, check PTP, statime, and the live Dante routing first
- This document is now an archive summary, not an active troubleshooting runbook
