# Desktop Design Document

A living document capturing intended desktop workflow, workspace layout, keybind philosophy,
and app requirements. Drives niri config (`_niri-settings.nix`) on Linux and OmniWM config
on macOS, with shared conventions so muscle memory transfers between machines.

---

## Machines

| Host | OS | WM | Monitors |
|------|----|----|----------|
| THEBATTLESHIP | NixOS (x86_64-linux) | niri | Always docked: ultrawide + 2× 1440p |
| voyager | macOS (aarch64-darwin) | OmniWM | Docked: same 3 monitors. Undocked: laptop screen only |

Both machines dock to the **same 3 external monitors**. Both need to handle:
- **Docked mode**: ultrawide + 2× 1440p — use monitor roles below
- **Undocked mode** (voyager only): single laptop screen — all workspaces on one display

**Cross-platform goal**: identical workspace names, identical keybind mnemonics, identical
app-to-workspace assignment. Where the WMs differ in capability, match the feel not the
implementation. Monitor names differ (Linux DRM vs macOS display IDs) but physical layout is
the same.

---

## Use Cases / Needs

### Music Production
- DAW: **REAPER**
- Multiple REAPER windows across monitors simultaneously:
  - Arrangement/timeline → center ultrawide
  - MIDI editor → left 1440p
  - Mixer → right 1440p (or swap with browser as needed)
- Plugin editors and patch browsers as floating windows
- Modes handled by switching individual monitors between workspaces — not a global layout change
- Needs fixed FPS mode (disable VRR) for audio sync — addressed via workflow profile
- Linux: PipeWire low-latency profile, JACK compat if needed

### Coding — Multiple Concurrent Projects
- 2–4 unrelated projects open simultaneously
- Each project = its own terminal + editor context (not tabs — separate workspaces)
- Some projects are related (frontend + backend), some unrelated
- Dev-Preview workspace: browser running localhost alongside code workspaces
- Apps: Neovim / Cursor / VS Code, kitty, Ghostty, lazygit

### Video Editing
- Timeline work needs wide horizontal space — ultrawide primary is ideal
- Prefers maximized or near-full-width column
- Apps: DaVinci Resolve

### Photo Editing / 3D Modeling
- Canvas-heavy work; floating toolboxes
- 3D viewport benefits from fullscreen
- Apps: GIMP, Inkscape, Blender

### Gaming
- Needs performance mode: strip animations, disable blur/shadows, fullscreen
- Steam launcher on secondary monitor, game on primary
- Apps: Steam (+ Lutris, Bottles for compatibility)

### AI / Research Tools
- ChatGPT, Claude, Perplexity etc. — live in `research` workspace alongside LibreWolf
- Keep AI tools co-located with research browser (same cognitive context)

### Notes & Default Browsing
- Always-available home workspace: notes, communication, general browsing
- Apps: Zen (general browsing), Obsidian, Discord, Signal, Gmail (webapp)

### Browsers — three with distinct responsibilities
| Browser | Workspace | Purpose |
|---------|-----------|---------|
| **Zen** | `home` | General browsing, companion to notes/comms |
| **Brave** | `media` | Passive media — YouTube, Netflix (Chromium compat) |
| **LibreWolf** | `research` | Active research — privacy-focused, no tracking |

Each browser stays on its assigned workspace. Separate cookie jars, separate histories.

---

## Workspace Layout

Workspaces are **semantically named**, not just numbered. Number keys switch between
them in order; semantic shortcuts provide fast access to key workspaces.

Same layout on all machines. On THEBATTLESHIP each monitor has its own independent workspace
stack. On voyager (laptop) all workspaces share the single screen.

### Primary workspaces (Mod+1–0)

| # | Name | Shortcut | Purpose | Key Apps |
|---|------|----------|---------|----------|
| 1 | `home` | `Mod+1` | Notes, comms, default landing | Obsidian, Zen, Discord, Signal, Gmail |
| 2 | `music` | `Mod+2` | DAW, audio tools | REAPER, plugins |
| 3 | `code-a` | `Mod+3` | Code project slot A (dynamic) | kitty, editor, lazygit |
| 4 | `code-b` | `Mod+4` | Code project slot B (dynamic) | kitty, editor, lazygit |
| 5 | `code-c` | `Mod+5` | Code project slot C / scratch | kitty, editor |
| 6 | `video` | `Mod+6` | Video editing | DaVinci Resolve |
| 7 | `creative` | `Mod+7` | Photo / 3D | GIMP, Blender, Inkscape |
| 8 | `media` | `Mod+8` / `Mod+M` | Passive media consumption | Brave (YouTube, Netflix) |
| 9 | `research` | `Mod+9` / `Mod+R` | Research, AI tools | LibreWolf, ChatGPT, Claude |
| 0 | `admin` | `Mod+0` | System, monitoring, admin | kitty, htop |

### Extended workspaces (semantic shortcuts only)

| Name | Shortcut | Purpose | Key Apps |
|------|----------|---------|----------|
| `gaming` | `Mod+Shift+G` | Gaming — performance mode | Steam, games |
| `dev-preview` | `Mod+P` | Live preview for active code project | Browser (localhost) |

### Semantic shortcuts
- `Mod+M` → `media` workspace
- `Mod+R` → `research` workspace
- `Mod+P` → `dev-preview` workspace
- `Mod+Shift+G` → `gaming` workspace
- `Mod+Shift+M/R` → move window to media/research

### Dynamic code slots
`code-a/b/c` are intentionally generic — reassign as projects come and go.
No permanent project names baked into config.

---

## Monitor Layout — THEBATTLESHIP & voyager (docked)

```
Left 1440p (DP-5)      Center ultrawide (DP-4)      Right 1440p (HDMI-A-2)
──────────────────     ──────────────────────────    ──────────────────────
  secondary context        main work surface            reference / comms
  MIDI / timeline          arrangement / editor         research / Discord
  2560×1440 @180Hz         5120×1440 @240Hz             2560×1440 @60Hz
```

Monitor identities confirmed from hyprland config (DP-5 @ 0,1440 = left; HDMI-A-2 @ 2560,1440 = right).

### Key concept: workspaces are per-monitor in niri

Each monitor has its own **independent** workspace stack. Switching workspaces on one monitor
doesn't affect the others.

**Full music mode** — REAPER across all 3:
```
Left (DP-5):   MIDI editor
Center (DP-4): Arrangement/timeline
Right (HDMI):  Mixer
```

**Music + browser** — just switch the right monitor:
```
Left (DP-5):   MIDI editor
Center (DP-4): Arrangement/timeline
Right (HDMI):  Research / browser   ← Mod+R on right monitor
```

**Code focus**:
```
Left (DP-5):   Secondary project / terminal
Center (DP-4): Primary editor
Right (HDMI):  Dev-preview / docs
```

### Undocked mode (single screen — voyager)
All workspaces exist on the one screen. Switch with `Mod+1–0`, `Mod+M`, `Mod+R` as normal.
Niri and OmniWM handle disconnect/reconnect automatically — no action needed on undock.

### Dock layout restore (which-key `l → d`)
After plugging back in, a script redistributes workspaces to their preferred monitors:
```bash
niri msg action focus-workspace research
niri msg action move-workspace-to-monitor HDMI-A-2   # research → right

niri msg action focus-workspace home
niri msg action move-workspace-to-monitor DP-4       # home → ultrawide

niri msg action focus-workspace code-a
niri msg action move-workspace-to-monitor DP-5       # code → left

niri msg action focus-monitor DP-4                   # return focus to center
```
Script lives as a store-path derivation in `_niri-settings.nix`.

---

## Workflow Profiles

Some workspaces benefit from different compositor settings. Profiles switch niri behavior
without changing the workspace layout. Triggered via which-key `l` submenu or direct bind.

| Profile | Trigger | Changes |
|---------|---------|---------|
| **Default** | `l → d` (or auto) | Normal gaps, animations, focus ring |
| **Music** | `l → m` | Disable VRR (fixed FPS for audio sync), reduce animations |
| **Gaming** | `l → g` | Strip all animations/blur, fullscreen Steam game |
| **Focus** | `l → f` | Dim inactive windows, hide bar, tighter gaps |
| **Video** | `l → v` | Maximize DaVinci on ultrawide, disable distracting effects |

In niri, profile switching is a shell script calling `niri msg action` to apply settings
at runtime (gaps, animation config changes require reload; others can be hot-applied).

---

## Keybind Philosophy

### Shared across both WMs (muscle memory layer)
| Action | Bind |
|--------|------|
| Open terminal (kitty) | `Mod+Return` |
| Open terminal (Ghostty) | `Mod+E` |
| Open Obsidian | `Mod+N` |
| Launcher / app search | `Mod+S` |
| Which-key / menu | `Mod+d` |
| Close window | `Mod+Q` |
| Focus left/right/up/down | `Mod+H/L/K/J` |
| Move window left/right | `Mod+Shift+H/L` |
| Resize wider/narrower | `Mod+Ctrl+H/L` |
| Switch workspace | `Mod+1–0` |
| Move window to workspace | `Mod+Shift+1–0` |
| Fullscreen | `Mod+G` |
| Maximize column | `Mod+F` |
| Float toggle | `Mod+Shift+F` |
| Lock screen | `Mod+Alt+L` |
| Quit / logout | `Mod+Shift+Q` |
| Volume up/down/mute | `XF86Audio*` |
| Brightness up/down | `XF86MonBrightness*` |
| Night shift toggle | `Mod+F2` |

`Mod` = Super on Linux host session, Alt when niri is nested, Option on macOS.

### Semantic workspace shortcuts (both WMs)
| Action | Bind |
|--------|------|
| Jump to media | `Mod+M` |
| Jump to research | `Mod+R` |
| Jump to dev-preview | `Mod+P` |
| Jump to gaming | `Mod+Shift+G` |
| Move window to media | `Mod+Shift+M` |
| Move window to research | `Mod+Shift+R` |

### niri-only additions
| Action | Bind |
|--------|------|
| Center column | `Mod+C` |
| Cycle column widths | `Mod+W` (preset: 1/3, 1/2, 2/3, full) |
| Screenshot region | `Mod+Shift+S` |
| Screenshot → annotate | `Mod+Shift+E` |
| Screenshot fullscreen | `Mod+Ctrl+S` |
| Built-in overview | `Mod+O` |

### Planned additions
- `Mod+Tab` — jump to last workspace
- `Mod+grave` — quake-style dropdown terminal (floating kitty)
- Run-or-raise behavior: if app already open, focus it; if focused, cycle instances

### Which-key menu (`Mod+d`) — full planned layout
```
b  LibreWolf          → research workspace (browser)
m  Brave              → media workspace
z  Zen                → home workspace
v  Vesktop (Discord)
a  ChatGPT / AI       → research workspace
s  Sound (pavucontrol)
n  Night shift toggle
l  Layout ▶
   d  Default layout  — restore default profile
   m  Music mode      — fixed FPS, reduced animations
   g  Gaming mode     — strip effects, performance
   f  Focus mode      — dim inactive, hide bar
   r  Dock restore    — redistribute workspaces to home monitors
p  Power ▶
   l  Lock
   r  Reboot
   p  Poweroff
   e  Logout (niri)
```

---

## Window Rules (Planned for niri)

| App | Workspace | Output (docked) | Width | Extra |
|-----|-----------|-----------------|-------|-------|
| Zen | `home` | DP-4 (ultrawide) | 0.67 | |
| Obsidian | `home` | DP-4 | 0.5 | |
| Discord / Signal | `home` | HDMI-A-2 (right) | 0.5 | |
| Gmail webapp | `home` | HDMI-A-2 (right) | 0.5 | |
| REAPER | `music` | DP-4 | full | open maximized |
| DaVinci Resolve | `video` | DP-4 | full | open maximized |
| Blender | `creative` | DP-4 | full | open maximized |
| GIMP | `creative` | DP-4 | 0.67 | |
| Brave | `media` | DP-4 | full | |
| LibreWolf | `research` | DP-4 | 0.67 | |
| Steam (game) | `gaming` | DP-4 | full | open fullscreen |
| Steam (launcher) | `gaming` | DP-5 (left) | 0.5 | open floating |
| pavucontrol | any | — | — | open floating |
| blueman-manager | any | — | — | open floating |
| 1Password | any | — | — | open floating, `block-out-from = "screencast"` |
| File dialogs | any | — | — | open floating |
| Picture-in-Picture | any | — | — | open floating, pin (always on top) |
| REAPER plugins | `music` | — | — | open floating, shadow |

---

## Apps Reference

| App | Category | Notes |
|-----|----------|-------|
| kitty | terminal | default, `Mod+Return` |
| Ghostty | terminal | alternative, `Mod+T` |
| Obsidian | notes | `Mod+N`, home workspace |
| Zen | browser | home workspace |
| Brave | browser | media workspace |
| LibreWolf | browser | research workspace |
| REAPER | DAW | music workspace |
| DaVinci Resolve | video | video workspace |
| Blender | 3D | creative workspace |
| GIMP | image | creative workspace |
| Inkscape | vector | creative workspace |
| Steam | gaming | gaming workspace |
| Discord (Vesktop) | comms | home workspace, right monitor |
| Signal | comms | home workspace, right monitor |
| pavucontrol | audio | floating, via which-key |
| blueman-manager | bluetooth | floating, via which-key panel |
| 1Password | passwords | floating, block from screencast |
| Flameshot / grim+slurp | screenshot | `Mod+Shift+S` |
| wl-clipboard + cliphist | clipboard | `Mod+Shift+C` — clipboard history picker |
| hyprsunset / wlsunset | night shift | `Mod+F2` toggle |

---

## OmniWM (macOS / voyager)

OmniWM config lives at `~/.config/omniwm/settings.json`. Supports niri-columns layout,
named workspaces, app rules, and fully custom keybinds.

Integration plan:
- Manage `settings.json` via home-manager `xdg.configFile` on darwin
- Mirror workspace names and keybind table above
- Use OmniWM's app rules for workspace auto-assignment
- Install via homebrew: `brew tap BarutSRB/tap && brew install omniwm`

OmniWM limitations vs niri:
- No scripting API (JSON config only) — workflow profiles not possible
- Multi-monitor: functional but rough edges
- No per-output workspace assignment — dock restore script not applicable

---

## Niri-Specific Features to Leverage

- **`preset-column-widths`** — cycle 1/3 → 1/2 → 2/3 → full with `Mod+W`
- **`struts`** — reserve space for noctalia bar
- **`window-rules`** — auto open-on-workspace, default widths, block-out-from, floating
- **`open-on-output`** — pin app categories to specific monitors when docked
- **Animations** — tune spring for snappy-but-smooth scrolling
- **`block-out-from = "screencast"`** — 1Password, sensitive terminals
- **`is-focused`** / `is-active`** window rules — dim inactive for focus mode

---

## Open Questions

- [x] DAW: REAPER — needs PipeWire low-latency profile
- [x] Browsers: Zen (home), Brave (media), LibreWolf (research)
- [x] Monitor identities: DP-5 = left, HDMI-A-2 = right, DP-4 = ultrawide
- [x] Dock-restore script designed — implement in `_niri-settings.nix`
- [x] Undock: let niri auto-manage window placement on disconnect
- [x] Note-taking: Obsidian
- [x] Code workspaces: dynamic slots (code-a/b/c), no permanent names
- [x] Gaming: `Mod+Shift+G`, dedicated workspace, Steam window rules
- [x] Which-key keys: `b`=LibreWolf, `m`=Brave, `z`=Zen, `l`=Layout submenu (no conflict)
- [ ] voyager: confirm macOS display names for OmniWM output config
- [ ] Workflow profiles: implement as niri reload scripts or runtime `niri msg` calls?
- [ ] Clipboard history: cliphist + wl-paste picker, bind to `Mod+Shift+C`
- [ ] Night shift: wlsunset (NixOS service) or hyprsunset? Toggle bind `Mod+F2`
- [ ] Quake terminal: floating kitty via niri window rule + scratchpad script
- [ ] OmniWM keybind JSON — write manually or generate from shared Nix data?
