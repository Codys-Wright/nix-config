# Audio System Issues - THEBATTLESHIP

**Date:** 2026-04-20  
**Status:** Partially Resolved  
**Priority:** High - Dante audio system showing incorrect latency

## Update History

### 2026-04-20 19:20 - Partial Fix Applied

**Fixed:** Duplicate asound.conf entries by removing `<fleet.music/production/inferno>` from `users/cody/cody.nix`.

**Current Status:**
- ✅ asound.conf now has single clean configuration
- ✅ Inferno nodes (sink/source) created and running
- ✅ Inferno set as default audio sink/source
- ⚠️ Dante latency still reporting incorrectly (check Dante Controller)

## Current Problem

### Issue 1: Dante Latency Showing 44700000ms (Should be 10ms)

The Dante/Dante Controller interface is reporting an average latency of **44,700,000 ms** for the Inferno service, which is obviously incorrect. The configuration is set to:

- **Configured:** 10ms (10000000 ns in asound.conf)
- **Reported:** 44,700,000ms

### Issue 2: Duplicate asound.conf Entries

The `/etc/asound.conf` file contains **duplicate entries** for the Inferno PCM device:

```bash
$ cat /etc/asound.conf
# First copy
pcm!default { type null }
ctl!default { type null }
pcm.inferno {
  type inferno
  RX_LATENCY_NS "10000000"
  TX_LATENCY_NS "10000000"
  ...
}

# Second copy (identical)
pcm!default { type null }
ctl!default { type null }
pcm.inferno {
  type inferno
  RX_LATENCY_NS "10000000"
  TX_LATENCY_NS "10000000"
  ...
}
```

**Root Cause:** The `fleet.music/production/inferno` aspect is being included twice:

1. **Via THEBATTLESHIP host config:** `hosts/THEBATTLESHIP/THEBATTLESHIP.nix` includes `<fleet.music/production>` which pulls in `production.nix` → `inferno.nix`
2. **Via cody user config:** `users/cody/cody.nix` directly includes `<fleet.music/production/inferno>`

Since NixOS merges configurations, this results in duplicate entries in the final `environment.etc."asound.conf".text`.

## System Status

### Services Running

| Service | Status | Notes |
|---------|--------|-------|
| pipewire.service | Active (running) | System-wide daemon as `pipewire` user |
| pipewire-pulse.service | Active (running) | PulseAudio bridge |
| wireplumber.service | Active (running) | Session manager |
| inferno-pipewire-sink.service | Active (exited) | Creates Inferno sink node |
| inferno-pipewire-source.service | Active (exited) | Creates Inferno source node |
| statime-inferno.service | Active (running) | PTP daemon for clock sync |

### PipeWire Nodes Created

- **Node 38:** "Inferno sink" (id: 42, serial: 42, running)
- **Node 45:** "Inferno source" (id: 45, serial: 50, running)
- Both nodes show `node.driver = true` and `state: running`

### Inferno Logs (Normal Operations)

```
[device_server] clock path: Some("/dev/ptp0")
[device_server] clock ready
[channels_subscriber] Ok(AdvertisedChannel { ... min_rx_latency_ns: 250000 ... })
```

**Note:** The `received unknown opcode1 0x3010` errors are **harmless** - these are unhandled Dante control messages, not audio errors.

### PTP Clock Status

- **PTP daemon:** statime running on enp12s0 (10.10.10.10)
- **Clock device:** /dev/ptp0 accessible (pipewire user in clock group)
- **Clock state:** "clock ready" in logs

### Dante Device Discovery

- Device at 10.10.10.118 is visible and communicating
- Dante flows are being requested and established
- Audio subscription to Yamaha TF is active

## Configuration

### asound.conf (Current - Duplicated)

```
RX_LATENCY_NS: 10000000 (10ms)
TX_LATENCY_NS: 10000000 (10ms)
SAMPLE_RATE: 48000
RX_CHANNELS: 2
TX_CHANNELS: 2
CLOCK_PATH: /dev/ptp0
```

### PipeWire Configuration

```
default.clock.rate: 48000
default.clock.quantum: 256 (5.3ms at 48kHz)
default.clock.min-quantum: 32
default.clock.max-quantum: 1024
```

### Inferno Node Latency Params

```
minQuantum: 1.000000
maxQuantum: 1.000000
minRate: 128
maxRate: 128
```

## Hypotheses for 44700000ms Latency

1. **Duplicated asound.conf:** The duplicate configuration might be causing ALSA to read wrong values
2. **PTP Clock Sync Issues:** Clock might not be properly synchronized with Dante network
3. **Inferno Plugin Bug:** Possible bug in the Inferno ALSA plugin when calculating/reporting latency
4. **WirePlumber/Default Configuration:** The wireplumber default config might be reporting wrong values
5. **Period Size Mismatch:** Inferno configured for 1024 period size but PipeWire using 256 quantum

## Investigation Checklist

- [ ] Fix duplicate asound.conf by removing `<fleet.music/production/inferno>` from cody.nix
- [ ] Check Dante Controller for actual latency measurements
- [ ] Verify PTP clock synchronization status (offset from grandmaster)
- [ ] Check if the Yamaha TF Dante device has correct latency settings
- [ ] Verify wireplumber is properly recognizing Inferno nodes as default devices
- [ ] Test audio playback/recording to verify actual (not reported) latency

## Immediate Next Steps

1. **Remove duplicate inferno include** from `users/cody/cody.nix` line 139
2. **Re-deploy** the configuration
3. **Verify** asound.conf has single entries
4. **Check** Dante Controller latency display after fix
5. **If still wrong:** Add debug logging to Inferno or check PTP sync status

## Related Files

- `/home/cody/.flake/hosts/THEBATTLESHIP/THEBATTLESHIP.nix` - Host configuration
- `/home/cody/.flake/users/cody/cody.nix` - User configuration (has duplicate include)
- `/home/cody/.flake/modules/music/production/inferno.nix` - Inferno service definition
- `/home/cody/.flake/modules/music/production/production.nix` - Production facet includes inferno
- `/home/cody/.flake/modules/hardware/audio/pipewire/pipewire.nix` - PipeWire configuration
- `/etc/asound.conf` - ALSA configuration (generated, do not edit directly)

## Notes

- The `unknown opcode 0x3010` errors are not the cause of the latency issue
- Audio flows are being established successfully
- PTP clock is accessible and ready
- The issue appears to be in latency reporting, not necessarily audio quality
