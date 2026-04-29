# THEBATTLESHIP audio stack — how it works

A study guide for the whole pipeline: PTP → Dante (Inferno) → ALSA plugin → PipeWire → app-facing virtual sinks/sources → OBS / Reaper / browser. Read top to bottom; each layer assumes the one above is already running.

```
┌────────────────────────────────────────────────────────────────────────┐
│  Studio Dante network (10G, enp12s0, 10.10.10.0/24)                    │
│   • Galaxy32 console (10.10.10.118)                                    │
│   • Apollo x16D (10.10.10.130)                                         │
│   • Yamaha NY64-D / Tio1608-D                                          │
│   • THEBATTLESHIP (this host, 10.10.10.10) — appears as a 128/128 dev  │
└────────────────────────────────────────────────────────────────────────┘
                              ▲
                              │  Dante AoIP frames (UDP, multicast + unicast)
                              │  ARC control on port 4400 (mDNS-advertised)
                              ▼
┌────────────────────────────────────────────────────────────────────────┐
│  Inferno-AoIP (FastTrackStudios fork)                                  │
│   • alsa_pcm_inferno.so loaded by PipeWire's ALSA adapter              │
│   • Single DeviceServer for sink+source (shared DEVICE_ID)             │
│   • statime keeps the kernel PTP clock locked to Galaxy32 (preferred   │
│     leader AA-4202524000109)                                           │
└────────────────────────────────────────────────────────────────────────┘
                              ▲
                              │  ALSA  pcm.inferno_sink   (RX 128, TX 128)
                              │        pcm.inferno_source (RX 128, TX 128)
                              ▼
┌────────────────────────────────────────────────────────────────────────┐
│  PipeWire (system-wide, low-latency, 48 kHz / 256-sample quantum)      │
│                                                                        │
│   ┌──────────────┐   ┌──────────────┐                                  │
│   │ Inferno sink │   │Inferno source│   <- ALSA adapters               │
│   │  playback_1  │   │  capture_1   │      (numeric port names —       │
│   │       …      │   │       …      │       audio.position = ["UNK"…]) │
│   │  playback_128│   │  capture_128 │                                  │
│   └──────┬───────┘   └──────┬───────┘                                  │
│          │                  │                                          │
│   ┌──────┴──────────┐  ┌────┴──────────────┐                           │
│   │ Studio loopbacks│  │ Studio loopbacks  │                           │
│   │   (TX side)     │  │   (RX side)       │                           │
│   │                 │  │                   │                           │
│   │ system_audio    │  │ talkback_mic      │                           │
│   │ system_notif…   │  │ talkback_mic_dsp  │                           │
│   │ voice_chat      │  │                   │                           │
│   │ games           │  │                   │                           │
│   │ daw (128-ch)    │  │                   │                           │
│   └─────┬───────────┘  └────┬──────────────┘                           │
│         │ Audio/Sink        │ Audio/Source                             │
└─────────┼───────────────────┼──────────────────────────────────────────┘
          ▼                   ▲
   apps stream into       apps capture from
   these like any         these like any mic
   stereo speaker
```

---

## Layer 1 — Dante network

**Box:** the studio runs a 10 GbE Dante network on `enp12s0`. Static IP `10.10.10.10/24` (outside the dnsmasq DHCP range so peer hosts can SSH in deterministically). The interface is added to `trustedInterfaces` so the firewall doesn't get in the way of Dante's ephemeral receive ports.

**PTP clock sync:** Dante demands sub-microsecond clock alignment. We don't run timesyncd — instead, [`statime`](https://github.com/pendulum-project/statime) is launched as a system service that locks `/dev/ptp0` to Galaxy32 (`AA-4202524000109`, the elected grandmaster). `services.timesyncd.enable = false;` because two clock daemons fighting over the system clock breaks sync.

**Files:**
- `hosts/THEBATTLESHIP/THEBATTLESHIP.nix` → `(fleet.music._.production._.statime { … })` and `(fleet.system._.network-10g { … })`.
- Disabled `timesyncd` and the open Dante firewall ports in the same module.

## Layer 2 — Inferno-AoIP (Dante in software)

[Inferno-AoIP](https://github.com/teodly/inferno) is an unofficial Rust implementation of Dante's protocols. We use a fork at `github.com/FastTrackStudios/inferno`, pinned in `packages/inferno/inferno.nix`.

It builds two artifacts we care about:
- `inferno2pipe` — a CLI that becomes a Dante device dumping samples to a pipe (used for testing / scripting).
- `libasound_module_pcm_inferno.so` — an **ALSA PCM plugin** that, when opened, *becomes* a Dante device on the network and exposes its 128 RX channels as ALSA capture and 128 TX channels as ALSA playback.

**Key design choice — one Dante device, two PCMs.** Real Dante devices have one TX and one RX channel set. We want PipeWire to see them as a separate ALSA sink and source so apps can route audio in and out independently. The plugin supports this via shared `DEVICE_ID`: both `pcm.inferno_sink` and `pcm.inferno_source` declare the same `DEVICE_ID="00000A0A0A0A0001"`, so they share *one* in-process `DeviceServer` (and therefore appear as a single device on the Dante network with TX=128 RX=128).

**ALT_PORT quirk** — the second PCM would otherwise collide on Dante's standard ARC port 4440. So `inferno_sink` sets `INFERNO_ALT_PORT=4400` (range 4400-4403) and `inferno_source` sets `INFERNO_ALT_PORT=4410` (range 4410-…). The actual ARC port the device advertises over mDNS is whichever port range was opened — in practice, **4400, not 4440**. Anything talking to Inferno's ARC must read the port from mDNS, not assume the Dante default. (The `set_dante_channel_names.py` script learned this the hard way; see `scripts/set_dante_channel_names.py:_arc_port`.)

**ARC protocol fix for netaudio** — netaudio's ARC packets use an 8-byte top-level header; Inferno parses 10. The 2-byte gap shifts every subsequent offset, so netaudio's `starting_channel` field landed at content bytes 2–3 while Inferno's `extract_start_index` was reading bytes 4–5. Result: every paginated channel-list request returned an empty page. The fix in `inferno_aoip/src/protocol/proto_arc.rs` accepts either layout — bytes 4–5 first, falling back to 2–3 if zero.

**Files:**
- `packages/inferno/inferno.nix` — pinned source + cargo build.
- `packages/netaudio/netaudio.nix` — pinned netaudio CLI (also a FastTrackStudios fork).
- `modules/music/production/inferno.nix` — generates `/etc/asound.conf` with the two PCM definitions and tells PipeWire to open them as ALSA card 999. **Critical:** `audio.position = lib.replicate channels "UNK"` — this is what makes PipeWire emit ports named `playback_1..128` / `capture_1..128` instead of `playback_FL/FR/AUX0/…`.

## Layer 3 — PipeWire

System-wide PipeWire (one server, all users see the same graph) running 48 kHz / 256-sample quantum. JACK + PulseAudio compatibility shims enabled. Boot behavior: socket activation off, the service is wired into `multi-user.target` directly so it starts before any user logs in. A per-user `pipewire-system-bridge` oneshot symlinks the system runtime sockets into `$XDG_RUNTIME_DIR` and exports `PULSE_SERVER` so apps see PipeWire the moment a user lingers in.

**`LimitNOFILE = 524288`** — every PipeWire link allocates a few file descriptors (eventfds, shm). With ~140 static studio links plus the ones from active apps, the systemd default 1024/4096 trips the daemon and you see `error alloc buffers: Too many open files`.

**Files:**
- `modules/hardware/audio/pipewire/pipewire.nix` — base config, USB Pro Audio quirks (Yamaha TF + Fractal: turn off ACP), the user-runtime bridge, and the FD limit.

## Layer 4 — Studio virtual nodes

This is where the per-app routing actually happens. All defined in `hosts/THEBATTLESHIP/THEBATTLESHIP.nix` under `services.pipewire.extraConfig.pipewire."93-studio-virtual-nodes"`.

### Pattern A — routed sink (apps → Dante)

```
┌────────────┐   loopback (2-ch)   ┌──────────────────────┐
│ system_    │  ─────────────────► │ system_audio_to_     │
│ audio      │                     │ inferno              │
│ Audio/Sink │                     │ Stream/Output/Audio  │
│ (apps      │                     │  output_1 ──┐        │
│  stream    │                     │  output_2 ─┐│        │
│  here)     │                     └────────────┘│        │
└────────────┘                                   ▼▼
                                       Inferno sink:playback_97/98
```

Each routed sink is a single `libpipewire-module-loopback` with two halves:
- **`capture.props`** — `media.class = "Audio/Sink"`, this is the node apps see and stream into.
- **`playback.props`** — the side that pushes into Inferno. `node.autoconnect = false` here is critical (see "Why `node.autoconnect`" below).

### Pattern B — routed source (Dante → apps)

```
                           Inferno source:capture_51/52
                                       │
                                       ▼
┌──────────────────────┐  loopback   ┌─────────────┐
│ talkback_mic_from_   │ ─────────► │ talkback_   │
│ inferno              │             │ mic         │
│ Stream/Input/Audio   │             │ Audio/Source│
│  input_1 ◄┐          │             │ (apps see   │
│  input_2 ─┘          │             │  this as a  │
│ node.autoconnect=    │             │  mic)       │
│   false              │             │             │
└──────────────────────┘             └─────────────┘
```

### Pattern C — DAW pass-through

The DAW sink is a 128-channel loopback that pipes 1:1 into Inferno sink. Reaper sees a single 128-ch device and uses the chanmap to label tracks.

### Why `node.autoconnect = false`?

WirePlumber 0.5's linking-policy script (`src/scripts/linking/rescan.lua`) sees every newly-created `Stream/Output/Audio` node and tries to wire it into the default sink. The default sink here is `Inferno sink` (128 channels). When a 2-channel loopback's playback-side stream got auto-linked, the policy *grew the loopback's port count to 128* to match the sink and wired all 128 in sequence — completely defeating the point of pinning specific channels.

Setting `node.autoconnect = false` (with `node.dont-reconnect = true` belt-and-suspenders, plus a `wireplumber.extraConfig` `node.rules` entry that re-applies the same flag on names matching `~.*_to_inferno` or `~.*_from_inferno`) makes the linking policy bail out in its `if not si_props["node.autoconnect"]` early-return, so these nodes stay quiet until the routing service wires them by hand.

## Layer 5 — `studio-routing-links` systemd service

WirePlumber 0.5 has no declarative static-link config (no `source-port`/`target-port` field anywhere in the schema). PipeWire's `context.objects` factory invocations are evaluated synchronously at daemon startup, and if the target port doesn't exist yet, **the daemon dies with `Invalid argument`** — and our loopback ports register asynchronously, so they reliably aren't there in time.

So we use a oneshot:

1. **Wait** up to 60 s for `Inferno sink` *and* `Inferno source` to appear in `pw-cli ls Node`. They're slow because the Inferno DeviceServer has to negotiate with peer Dante devices first.
2. For each `(out, in)` port pair, **try `pw-link` with retries** (10 attempts, 1 s apart). pw-link refuses to duplicate an existing link, so reruns are idempotent.
3. Exits 0 on success — `RemainAfterExit = true` so systemd treats the unit as "active" until pipewire restarts.

Pairs come from a single source-of-truth at the top of the host module:

```nix
let
  studioRoutedSinks = [
    { name = "system_audio";         desc = "System Audio";         txL = 97;  txR = 98;  }
    { name = "system_notifications"; desc = "System Notifications"; txL = 99;  txR = 100; }
    { name = "voice_chat";           desc = "Voice Chat";           txL = 101; txR = 102; }
    { name = "games";                desc = "Games";                txL = 97;  txR = 98;  }  # shares with System Audio
  ];
  studioRoutedSources = [
    { name = "talkback_mic";     desc = "Talkback Mic";       rxL = 51; rxR = 52; }
    { name = "talkback_mic_dsp"; desc = "Talkback Mic [DSP]"; rxL = 90; rxR = 91; }
  ];
in …
```

The PipeWire-config block uses these to *create* the loopback nodes; the systemd service uses the same lists to *link* them. Change a channel number once, both ends pick it up.

## Layer 6 — apps

| App | Picks | Goes to |
|-----|-------|---------|
| Browser music / system sounds | `System Audio` sink | TX 97/98 → Dante → console |
| Notification sounds (libnotify) | `System Notifications` sink | TX 99/100 |
| Discord / Element / etc. | `Voice Chat` sink | TX 101/102 |
| Games (gameaudio capture for OBS) | `Games` sink | TX 97/98 (mixed with System Audio at the console; *but* OBS can record Games as its own track) |
| OBS scene audio source | `Games` (or any other studio sink) as a **monitor source** | recorded into the OBS file |
| Reaper | `DAW` (128 ch) | TX 1..128 → console (one channel per ChanMap entry) |
| Voice-chat **mic** | `Talkback Mic` source | RX 51/52 (Producer/Generic talkback raw) |
| Vocal alignment monitor | `Talkback Mic [DSP]` source | RX 90/91 (post-DSP) |

Channel numbers correspond to entries in `~/.fasttrackstudio/Reaper/ChanMaps/THEBATTLESHIP.ReaperChanMap`. Renaming Dante channels to match the chanmap is a one-shot:

```bash
python3 scripts/set_dante_channel_names.py --device THEBATTLESHIP --channel-type tx
python3 scripts/set_dante_channel_names.py --device THEBATTLESHIP --channel-type rx
```

That script reads `nameN=…` lines out of the chanmap and pushes each name to inferno via netaudio. It looks the ARC port up from mDNS instead of hard-coding 4440, which matters because of the ALT_PORT quirk in Layer 2.

---

## Operational reference

### Verify the graph

```bash
# Are studio sinks/sources present?
pw-cli ls Node | grep -E 'node.name = "(system_audio|games|voice_chat|talkback_mic)"'

# Did the link service finish?
systemctl status studio-routing-links

# What's actually wired?
pw-link -l | grep -E 'system_audio_to_inferno|games_to_inferno'
```

Expected: `system_audio_to_inferno:output_{1,2} → Inferno sink:playback_{97,98}` and the same for games (also 97/98), notifications (99/100), voice_chat (101/102). 128 lines for `daw_to_inferno`. Two source-side links each for `talkback_mic_from_inferno` and `talkback_mic_dsp_from_inferno`.

### Restart sequence

```bash
sudo systemctl restart pipewire
sleep 8
sudo systemctl restart studio-routing-links
```

The link service waits for Inferno to appear, but if you skip the sleep on a slow Dante negotiation it'll spend its retry budget without finding the nodes. Restart it manually if needed.

### Where things live

| File | Purpose |
|------|---------|
| `hosts/THEBATTLESHIP/THEBATTLESHIP.nix` | the host module — defines `studioRoutedSinks` / `studioRoutedSources`, builds the loopback nodes, ships `studio-routing-links` |
| `modules/hardware/audio/pipewire/pipewire.nix` | system-wide PipeWire base, FD limit, USB-audio quirks, the user-runtime bridge |
| `modules/music/production/inferno.nix` | the parametric Inferno aspect — emits `asound.conf` and the two PipeWire ALSA adapters; UNK channel positions live here |
| `packages/inferno/inferno.nix` | pinned FastTrackStudios fork rev + cargo hash |
| `packages/netaudio/netaudio.nix` | pinned netaudio fork (with the channel-count + RX-pagination fixes) |
| `scripts/set_dante_channel_names.py` | bulk-renamer that reads the Reaper ChanMap and pushes names to Inferno over ARC |

### Common failure modes & where to look

| Symptom | Likely cause | Where to check |
|--------|-------------|----------------|
| `netaudio device list` doesn't see THEBATTLESHIP | Inferno crashed (mDNS bind, ALSA config, etc.) | `journalctl -u pipewire | grep -iE 'panic\|asound_module_pcm_inferno\|inferno_aoip'` |
| `netaudio` sees device with 128/128 but `channel list` is empty | Old Inferno without the ARC-bytes fix | `packages/inferno/inferno.nix` rev pin — should include `c1ab4ce` or later |
| Renames "succeed" but nothing changes | Script hard-coded port 4440 (ALT_PORT in use) | `scripts/set_dante_channel_names.py:_arc_port` |
| Loopback grew to 128 ports, all linked sequentially | `node.autoconnect = false` missing on a new node | inline in `mkRoutedSink/mkRoutedSource` *and* the WP `node.rules` glob |
| `pw.link: error alloc buffers: Too many open files` | systemd FD limit too low | `LimitNOFILE = 524288` on `pipewire.service` |
| Routing seems "stuck" after a hot-reload | `studio-routing-links` exited before nodes appeared | `systemctl restart studio-routing-links` |

---

## Why each non-obvious choice

**Numeric ports (`audio.position = ["UNK"…]`) over surround/AUX positions.**
PipeWire's port linker matches by position name when both ends have one and falls back to index-order when either is `UNK`. With surround/AUX everywhere, Inferno's 128 channels would appear as `playback_FL/FR/RL/RR/FC/LFE/SL/SR/AUX0..AUX119`, which is unreadable when you want channel 97 specifically. UNK gives plain `playback_97`, which is also what `pw-link` matches against by name.

**Systemd oneshot over WirePlumber Lua / PipeWire `context.objects`.**
WP 0.5's policy script is for *which* node to link, not *which port*; there's no static-link config. PipeWire's `context.objects` fails fatally when a target port doesn't exist yet at config-load time. `pw-link` from a oneshot waits for nodes to appear, retries on transient failures, and is idempotent. A WirePlumber Lua script could do this too, but it'd be substantially more code.

**Both `node.autoconnect = false` on the loopback props *and* a WirePlumber `node.rules` glob.**
PipeWire's libpipewire-module-loopback adapter sometimes drops props during channel re-negotiation. The WP `node.rules` block re-applies the flag whenever WP first sees the node, so even if the loopback's per-node prop disappears, WP still won't auto-link it.

**Games shares TX with System Audio, not its own pair.**
Two reasons: the chanmap has no Games L/R entries, and the studio uses a "one stereo bus" workflow where game audio is mixed into the same stereo monitor as system audio. But OBS still wants to record game audio as its own track, hence two distinct PipeWire sinks. They diverge in the PipeWire graph and converge again at Inferno TX 97/98.
