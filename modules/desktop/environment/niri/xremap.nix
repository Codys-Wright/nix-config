# xremap — macOS-style keybindings via full modifier swap
#
# Physical key layout after remapping:
#   Physical Alt   → Ctrl (Command)  — copy/paste/save/close/find
#   Physical Super → Alt  (Option)   — word navigation, special characters
#   Physical Ctrl  → Super (niri Mod) — window management
#
# Based on: github.com/Anas-Alhariri/Mac-Keyboard-Style-On-Linux
# Adapted for niri (wlroots) with per-app terminal/browser/editor exceptions.
#
# NOTE: In terminals, physical Ctrl sends terminal signals (SIGINT, EOF, etc.)
# via xremap before niri sees them. Use Mod+Arrow (physical Ctrl+Arrow) for
# niri window navigation when a terminal is focused, since Mod+H/J/K/L are
# consumed by terminal Ctrl signal remaps.
{
  FTS,
  inputs,
  ...
}:
{
  FTS.desktop._.environment._.niri._.xremap = {
    description = ''
      macOS-style keyboard shortcuts via xremap with full modifier swap.
      Physical Alt = Command, Physical Super = Option, Physical Ctrl = niri Mod.
    '';

    homeManager =
      { ... }:
      {
        imports = [ inputs.xremap-flake.homeManagerModules.default ];

        services.xremap = {
          enable = true;
          withNiri = true;
          config = {
            # ── Modifier swap ──────────────────────────────────────────────
            modmap = [
              {
                name = "Mac-style modifier swap";
                remap = {
                  Alt_L = "Ctrl_L";
                  Ctrl_L = "Super_L";
                  Super_L = "Alt_L";
                  Alt_R = "Ctrl_R";
                  Ctrl_R = "Super_R";
                  Super_R = "Alt_R";
                };
              }
            ];

            keymap = [
              # ── App / tab switching ────────────────────────────────────
              {
                name = "App and tab switching";
                remap = {
                  # Cmd+Tab = app switcher (physical Alt+Tab → Ctrl+Tab → Alt+Tab)
                  "Ctrl-Tab" = "Alt-Tab";
                  "Ctrl-Shift-Tab" = "Alt-Shift-Tab";
                  # Cmd+` = switch windows of same app
                  "Ctrl-grave" = "Alt-grave";
                  "Ctrl-Shift-grave" = "Alt-Shift-grave";
                  # Physical Ctrl+Tab = tab switching (→ Super+Tab → Ctrl+Tab)
                  "Super-Tab" = "Ctrl-Tab";
                  "Super-Shift-Tab" = "Ctrl-Shift-Tab";
                };
              }

              # ── Text navigation (excludes terminals & file managers) ───
              {
                name = "Text navigation and editing";
                application = {
                  not = [
                    # Terminals
                    "Alacritty"
                    "kitty"
                    "ghostty"
                    "foot"
                    "wezterm"
                    "org.wezfurlong.wezterm"
                    "org.gnome.Terminal"
                    "org.gnome.Console"
                    "org.gnome.Ptyxis"
                    "konsole"
                    "tilix"
                    "com.gexperts.Tilix"
                    "terminator"
                    # File managers (have their own shortcuts)
                    "org.gnome.Nautilus"
                    "nautilus"
                    "Nautilus"
                    "org.gnome.Files"
                    "dolphin"
                    "thunar"
                    "pcmanfm"
                    "nemo"
                    "caja"
                  ];
                };
                remap = {
                  # Cmd+Arrow = line/document navigation
                  "Ctrl-Left" = "Home";
                  "Ctrl-Right" = "End";
                  "Ctrl-Up" = "Ctrl-Home";
                  "Ctrl-Down" = "Ctrl-End";
                  # Cmd+Shift+Arrow = line/document selection
                  "Ctrl-Shift-Left" = "Shift-Home";
                  "Ctrl-Shift-Right" = "Shift-End";
                  "Ctrl-Shift-Up" = "Ctrl-Shift-Home";
                  "Ctrl-Shift-Down" = "Ctrl-Shift-End";
                  # Option+Arrow = word navigation
                  "Alt-Left" = "Ctrl-Left";
                  "Alt-Right" = "Ctrl-Right";
                  "Alt-Up" = "Ctrl-Up";
                  "Alt-Down" = "Ctrl-Down";
                  # Option+Shift+Arrow = word selection
                  "Alt-Shift-Left" = "Ctrl-Shift-Left";
                  "Alt-Shift-Right" = "Ctrl-Shift-Right";
                  "Alt-Shift-Up" = "Ctrl-Shift-Up";
                  "Alt-Shift-Down" = "Ctrl-Shift-Down";
                  # Delete shortcuts
                  "Alt-Backspace" = "Ctrl-Backspace"; # Option+Backspace = delete word left
                  "Ctrl-Backspace" = [
                    "Shift-Home"
                    "Backspace"
                  ]; # Cmd+Backspace = delete to line start
                  "Alt-Delete" = "Ctrl-Delete"; # Option+Delete = delete word right
                  "Ctrl-Delete" = [
                    "Shift-End"
                    "Delete"
                  ]; # Cmd+Delete = delete to line end
                  # Cmd+Q = quit application
                  "Ctrl-q" = "Alt-F4";
                };
              }

              # ── Browser shortcuts ──────────────────────────────────────
              {
                name = "Browser shortcuts";
                application = {
                  only = [
                    "firefox"
                    "Firefox"
                    "firefox-esr"
                    "librewolf"
                    "LibreWolf"
                    "zen"
                    "zen-browser"
                    "chromium"
                    "Chromium"
                    "google-chrome"
                    "Google-chrome"
                    "brave-browser"
                    "Brave-browser"
                    "Microsoft-edge"
                    "vivaldi"
                    "opera"
                    "epiphany"
                    "org.gnome.Epiphany"
                  ];
                };
                remap = {
                  # Cmd+[ / ] = back / forward
                  "Ctrl-leftbrace" = "Alt-Left";
                  "Ctrl-rightbrace" = "Alt-Right";
                  # Cmd+Shift+[ / ] = prev / next tab
                  "Ctrl-Shift-leftbrace" = "Ctrl-PageUp";
                  "Ctrl-Shift-rightbrace" = "Ctrl-PageDown";
                };
              }

              # ── File manager shortcuts ─────────────────────────────────
              {
                name = "File manager shortcuts";
                application = {
                  only = [
                    "org.gnome.Nautilus"
                    "nautilus"
                    "Nautilus"
                    "org.gnome.Files"
                    "dolphin"
                    "thunar"
                    "pcmanfm"
                    "nemo"
                    "caja"
                  ];
                };
                remap = {
                  "Ctrl-Up" = "Alt-Up"; # Cmd+Up = parent folder
                  "Ctrl-Down" = "Enter"; # Cmd+Down = open selected
                  "Ctrl-leftbrace" = "Alt-Left"; # Cmd+[ = back
                  "Ctrl-rightbrace" = "Alt-Right"; # Cmd+] = forward
                  "Ctrl-i" = "Alt-Enter"; # Cmd+I = properties
                  "Ctrl-Backspace" = "Delete"; # Cmd+Backspace = trash
                };
              }

              # ── Terminal apps ──────────────────────────────────────────
              {
                name = "Terminal apps";
                application = {
                  only = [
                    "Alacritty"
                    "kitty"
                    "ghostty"
                    "foot"
                    "wezterm"
                    "org.wezfurlong.wezterm"
                    "org.gnome.Terminal"
                    "org.gnome.Console"
                    "org.gnome.Ptyxis"
                    "konsole"
                    "tilix"
                    "com.gexperts.Tilix"
                    "terminator"
                  ];
                };
                remap = {
                  # ── Cmd shortcuts (physical Alt → Ctrl after modmap) ───
                  "Ctrl-c" = "Ctrl-Shift-c"; # Cmd+C = copy
                  "Ctrl-v" = "Ctrl-Shift-v"; # Cmd+V = paste
                  "Ctrl-t" = "Ctrl-Shift-t"; # Cmd+T = new tab
                  "Ctrl-w" = "Ctrl-Shift-w"; # Cmd+W = close tab
                  "Ctrl-n" = "Ctrl-Shift-n"; # Cmd+N = new window
                  "Ctrl-q" = "Alt-F4"; # Cmd+Q = quit
                  "Ctrl-k" = "Ctrl-Shift-k"; # Cmd+K = clear

                  # ── Physical Ctrl signals (physical Ctrl → Super) ──────
                  # These let you send terminal control sequences via physical Ctrl.
                  # Note: niri Mod+H/J/K/L won't work in terminals (use Mod+Arrow instead)
                  "Super-c" = "Ctrl-c"; # SIGINT
                  "Super-z" = "Ctrl-z"; # SIGTSTP (suspend)
                  "Super-d" = "Ctrl-d"; # EOF
                  "Super-l" = "Ctrl-l"; # Clear screen
                  "Super-r" = "Ctrl-r"; # Reverse search
                  "Super-a" = "Ctrl-a"; # Beginning of line
                  "Super-e" = "Ctrl-e"; # End of line
                  "Super-u" = "Ctrl-u"; # Kill line before cursor
                  "Super-k" = "Ctrl-k"; # Kill line after cursor
                  "Super-w" = "Ctrl-w"; # Delete word before cursor
                  "Super-y" = "Ctrl-y"; # Yank (paste killed text)
                  "Super-p" = "Ctrl-p"; # Previous command
                  "Super-n" = "Ctrl-n"; # Next command
                  "Super-f" = "Ctrl-f"; # Forward character
                  "Super-b" = "Ctrl-b"; # Backward character
                  "Super-t" = "Ctrl-t"; # Transpose characters
                  "Super-h" = "Ctrl-h"; # Backspace
                  "Super-g" = "Ctrl-g"; # Cancel
                  "Super-backslash" = "Ctrl-backslash"; # SIGQUIT
                };
              }

              # ── VS Code / Cursor ───────────────────────────────────────
              {
                name = "VS Code and Cursor";
                application = {
                  only = [
                    "code"
                    "Code"
                    "code-oss"
                    "Code - OSS"
                    "vscodium"
                    "VSCodium"
                    "cursor"
                    "Cursor"
                  ];
                };
                remap = {
                  # Cmd+Shift+/ = block comment (VS Code uses Ctrl+Shift+A)
                  "Ctrl-Shift-slash" = "Ctrl-Shift-a";
                  # Option+Arrow = word navigation (override text nav for consistency)
                  "Alt-Left" = "Ctrl-Left";
                  "Alt-Right" = "Ctrl-Right";
                };
              }
            ];
          };
        };
      };
  };
}
