# Niri Configuration Guide

Niri is a scrollable-tiling Wayland compositor. Configuration is defined in Nix via
[wrapper-modules](https://github.com/BirdeeHub/nix-wrapper-modules), which generates
a `config.kdl` in the nix store. **Do not edit config.kdl directly.**

## File Layout

| File | Purpose |
|------|---------|
| `modules/desktop/environment/niri/_niri-settings.nix` | All niri settings (keybinds, outputs, workspaces, window rules) |
| `modules/desktop/environment/niri/niri.nix` | FTS aspect: nixos/homeManager integration, system packages |
| `modules/desktop/environment/niri/niri-wrapper.nix` | Exposes wrapper-module for `nix run .#niri` |
| `modules/desktop/environment/niri/inputs.nix` | Flake input for niri-flake |

## Wrapper-Modules Format

The settings file uses wrapper-modules v2-settings format. Key patterns:

```nix
# Flag (no value) — generates bare KDL node
prefer-no-csd = _: { };

# String/number value — generates KDL node with argument
mode = "2560x1440@179.999";
gaps = 5;

# Attrset — generates KDL node with children
layout = {
  gaps = 5;
  focus-ring.width = 2;
};

# KDL properties (like position x=0 y=0) — use function returning props
position = _: {
  props = { x = 0; y = 1440; };
};

# List of strings for spawn — generates KDL node with multiple arguments
"Mod+Ctrl+S".spawn = [ "flameshot" "gui" "--clipboard" ];
```

## Output Configuration

Outputs are configured under `config.settings.outputs`. Each key is a connector name.

```nix
outputs = {
  "DP-4" = {
    mode = "5120x1440@240.000";
    variable-refresh-rate = _: { };  # enable VRR
    position = _: { props = { x = 0; y = 0; }; };
  };
};
```

Use `niri msg outputs` to find connector names and available modes.

**Notes:**
- VRR can cause flickering on OLED panels — test before enabling
- HDMI may be bandwidth-limited to lower refresh rates than DisplayPort
- Mode strings must match available modes exactly (use values from `niri msg outputs`)

## Named Workspaces

Named workspaces persist even when empty. Pin them to monitors with `open-on-output`.

```nix
workspaces = {
  w0 = { };          # generic workspace
  music = {
    open-on-output = "DP-4";  # pin to ultrawide
  };
};
```

## Window Rules

Use `window-rules` (plural) with `matches` list. Each list item generates a separate
`window-rule { }` block. Multiple match entries within one rule use OR logic.

```nix
window-rules = [
  {
    matches = [{ app-id = "^REAPER$"; title = "REAPER v"; }];
    open-on-workspace = "music";
    open-maximized = true;
  }
  {
    matches = [
      { app-id = "^equibop$"; }
      { app-id = "^vesktop$"; }
    ];
    open-on-workspace = "comms";
  }
];
```

**Finding app-id and title:** Run `niri msg windows` to see all open windows with
their app-id and title strings.

**Do NOT use `window-rule` (singular)** — that merges all rules into one block and
causes "duplicate node" errors.

## Keybinds

Keybinds are under `config.settings.binds`. The `Mod` key is Super on TTY, Alt when
nested in another compositor.

```nix
binds = {
  "Mod+Return".spawn = lib.getExe p.kitty;
  "Mod+Q".close-window = _: { };
  "Mod+H".focus-column-or-monitor-left = _: { };
  "Mod+Shift+H".move-column-left-or-to-monitor-left = _: { };
  "Mod+Ctrl+H".set-column-width = "-5%";
  "Mod+1".focus-workspace = "w0";
};
```

### Cross-Monitor Actions

Use the `-or-monitor-` variants for seamless multi-monitor navigation:

| Action | Description |
|--------|-------------|
| `focus-column-or-monitor-left/right` | Focus column, crosses to adjacent monitor |
| `focus-window-or-monitor-up/down` | Focus window in column, crosses monitors |
| `move-column-left-or-to-monitor-left/right` | Move column across monitors |
| `move-window-up-or-to-workspace-up/down` | Move window across workspaces |
| `focus-workspace-down/up` | Cycle workspaces on current monitor |

Run `niri msg action` for a full list of available actions.

## Which-Key Menu

The `mkWhichKeyExe` helper generates a wlr-which-key popup from a Nix list:

```nix
"Mod+d".spawn-sh = mkWhichKeyExe [
  { key = "b"; desc = "Browser"; cmd = "librewolf"; }
  { key = "p"; desc = "Power"; submenu = [
    { key = "l"; desc = "Lock"; cmd = "swaylock"; }
    { key = "r"; desc = "Reboot"; cmd = "reboot"; }
  ]; }
];
```

## Run-or-Raise

The `runOrRaise` helper focuses an existing window by app-id, or launches the app
if not running:

```nix
runOrRaise "equibop" "equibop"
# Returns path to a script that checks niri msg windows for matching app-id
```

Use this in which-key entries for singleton apps (Discord, browsers, Obsidian).

## Wallpaper

Currently using swaybg with a solid Catppuccin Mocha base color. Configured in
`spawn-at-startup`:

```nix
spawn-at-startup = [
  (lib.getExe (p.writeShellScriptBin "wallpaper" "${lib.getExe p.swaybg} -c '#1e1e2e'"))
];
```

To use an image instead: `"${lib.getExe p.swaybg} -i /path/to/wallpaper.png"`

## Debugging

```bash
niri msg outputs       # monitor info, modes, positions
niri msg windows       # all windows with app-id, title, workspace
niri msg workspaces    # workspace layout across monitors
niri msg action        # list all available actions
niri validate          # validate config without applying
```
