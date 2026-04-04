# Mac-style keyboard keybindings for Linux via xremap
#
# Generates a complete xremap config that emulates macOS keyboard behavior.
# Based on: github.com/Anas-Alhariri/Mac-Keyboard-Style-On-Linux
#
# Usage:
#   mkMacKeybindings { cmdKey = "super"; }  → Physical Super = Cmd (F20 virtual modifier)
#   mkMacKeybindings { cmdKey = "alt"; }    → Physical Alt = Cmd (original 3-way swap)
#
# Returns: an attrset suitable for services.xremap.config
{ lib }:
{
  # Which physical key acts as macOS "Cmd" (⌘)
  #   "super" → Physical Super = Cmd, Ctrl unchanged, Alt = Option
  #             Uses F20 virtual modifier. Best for WMs that use Super as Mod.
  #   "alt"   → Physical Alt = Cmd, Physical Super = Option, Physical Ctrl = Super
  #             Full 3-way swap (original Mac-Keyboard-Style-On-Linux behavior).
  cmdKey ? "super",

  # Additional modmap rules to prepend (e.g., Caps Lock → Super for WM mod)
  extraModmap ? [ ],

  # Additional keymap rules to append
  extraKeymap ? [ ],
}:
let
  isAltCmd = cmdKey == "alt";

  # ── Modifier prefix names (post-modmap) ──────────────────────────────
  # These determine what modifier name appears in keymap rules for each role.
  cmd = if isAltCmd then "Ctrl" else "F20"; # "Cmd" shortcuts
  opt = "Alt"; # "Option" shortcuts (Alt in both modes)
  physCtrl = if isAltCmd then "Super" else "Ctrl"; # Physical Ctrl (for terminal signals)

  # ── App lists ────────────────────────────────────────────────────────
  terminals = [
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
    "xterm"
    "urxvt"
    "st"
    "io.elementary.terminal"
  ];

  fileManagers = [
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

  browsers = [
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

  codeEditors = [
    "code"
    "Code"
    "code-oss"
    "Code - OSS"
    "vscodium"
    "VSCodium"
    "cursor"
    "Cursor"
  ];

  jetbrainsIdes = [
    "/jetbrains-.*/"
    "idea"
    "pycharm"
    "webstorm"
    "phpstorm"
    "goland"
    "clion"
    "rider"
    "datagrip"
    "rubymine"
    "android-studio"
  ];

  # ── Modmap ───────────────────────────────────────────────────────────
  modmap =
    if isAltCmd then
      [
        {
          name = "Mac-style modifier swap (Alt=Cmd, Super=Option, Ctrl=Super)";
          remap = {
            Alt_L = "Ctrl_L";
            Ctrl_L = "Super_L";
            Super_L = "Alt_L";
            Alt_R = "Ctrl_R";
            Ctrl_R = "Super_R";
            Super_R = "Alt_R";
          };
        }
      ]
    else
      [
        {
          name = "Physical Super → F20 (Cmd virtual modifier)";
          remap = {
            Super_L = "F20";
            Super_R = "F20";
          };
        }
      ];

  # Helper: prepend modifier to key name
  c = key: "${cmd}-${key}"; # Cmd+key
  cs = key: "${cmd}-Shift-${key}"; # Cmd+Shift+key
  o = key: "${opt}-${key}"; # Option+key
  os = key: "${opt}-Shift-${key}"; # Option+Shift+key
  pc = key: "${physCtrl}-${key}"; # Physical Ctrl+key

  # ── Keymap rules ─────────────────────────────────────────────────────
  keymap = [
    # ════════════════════════════════════════════════════════════════════
    # GLOBAL SHORTCUTS (all apps)
    # ════════════════════════════════════════════════════════════════════

    {
      name = "App and tab switching";
      remap =
        {
          # Cmd+Tab = app switcher
          "${c "Tab"}" = "Alt-Tab";
          "${cs "Tab"}" = "Alt-Shift-Tab";
          # Cmd+` = switch windows of same app
          "${c "grave"}" = "Alt-grave";
          "${cs "grave"}" = "Alt-Shift-grave";
        }
        // lib.optionalAttrs isAltCmd {
          # Physical Ctrl+Tab = tab switching (only needed with modmap swap)
          "Super-Tab" = "Ctrl-Tab";
          "Super-Shift-Tab" = "Ctrl-Shift-Tab";
        };
    }

    # ════════════════════════════════════════════════════════════════════
    # CMD SHORTCUTS — NON-TERMINAL APPS
    # ════════════════════════════════════════════════════════════════════

    {
      name = "Cmd shortcuts (non-terminal)";
      application.not = terminals;
      remap = {
        "${c "a"}" = "Ctrl-a"; # Select all
        "${c "c"}" = "Ctrl-c"; # Copy
        "${c "v"}" = "Ctrl-v"; # Paste
        "${c "x"}" = "Ctrl-x"; # Cut
        "${c "z"}" = "Ctrl-z"; # Undo
        "${cs "z"}" = "Ctrl-Shift-z"; # Redo
        "${c "s"}" = "Ctrl-s"; # Save
        "${cs "s"}" = "Ctrl-Shift-s"; # Save as
        "${c "f"}" = "Ctrl-f"; # Find
        "${c "g"}" = "Ctrl-g"; # Find next
        "${cs "g"}" = "Ctrl-Shift-g"; # Find previous
        "${c "h"}" = "Ctrl-h"; # Replace
        "${c "w"}" = "Ctrl-w"; # Close tab
        "${c "t"}" = "Ctrl-t"; # New tab
        "${cs "t"}" = "Ctrl-Shift-t"; # Reopen tab
        "${c "n"}" = "Ctrl-n"; # New window
        "${cs "n"}" = "Ctrl-Shift-n"; # New incognito/private
        "${c "o"}" = "Ctrl-o"; # Open
        "${c "p"}" = "Ctrl-p"; # Print / command palette
        "${c "l"}" = "Ctrl-l"; # Address bar / go to line
        "${c "r"}" = "Ctrl-r"; # Reload
        "${cs "r"}" = "Ctrl-Shift-r"; # Hard reload
        "${c "d"}" = "Ctrl-d"; # Bookmark / duplicate
        "${c "b"}" = "Ctrl-b"; # Bold / sidebar
        "${c "i"}" = "Ctrl-i"; # Italic / info
        "${c "u"}" = "Ctrl-u"; # Underline
        "${c "k"}" = "Ctrl-k"; # Link / command
        "${c "e"}" = "Ctrl-e"; # Search from address bar
        "${c "q"}" = "Alt-F4"; # Quit app (Cmd+Q)
        "${cs "q"}" = "Alt-F4"; # Quit (alternate)
        "${c "comma"}" = "Ctrl-comma"; # Preferences/settings
        "${c "slash"}" = "Ctrl-slash"; # Toggle comment
        "${cs "slash"}" = "Ctrl-Shift-slash"; # Block comment
        "${c "equal"}" = "Ctrl-equal"; # Zoom in
        "${c "minus"}" = "Ctrl-minus"; # Zoom out
        "${c "0"}" = "Ctrl-0"; # Reset zoom
      };
    }

    # ════════════════════════════════════════════════════════════════════
    # CMD SHORTCUTS — TERMINAL APPS
    # ════════════════════════════════════════════════════════════════════

    {
      name = "Cmd shortcuts (terminal)";
      application.only = terminals;
      remap =
        {
          "${c "c"}" = "Ctrl-Shift-c"; # Copy
          "${c "v"}" = "Ctrl-Shift-v"; # Paste
          "${c "t"}" = "Ctrl-Shift-t"; # New tab
          "${c "w"}" = "Ctrl-Shift-w"; # Close tab
          "${c "n"}" = "Ctrl-Shift-n"; # New window
          "${c "k"}" = "Ctrl-Shift-k"; # Clear
          "${c "f"}" = "Ctrl-Shift-f"; # Find
          "${c "q"}" = "Alt-F4"; # Quit
          "${c "comma"}" = "Ctrl-comma"; # Preferences
          "${c "equal"}" = "Ctrl-equal"; # Zoom in
          "${c "minus"}" = "Ctrl-minus"; # Zoom out
          "${c "0"}" = "Ctrl-0"; # Reset zoom
        }
        // lib.optionalAttrs isAltCmd {
          # With the modmap swap, physical Ctrl sends Super.
          # Re-route to actual Ctrl for terminal signals.
          "${pc "c"}" = "Ctrl-c"; # SIGINT
          "${pc "z"}" = "Ctrl-z"; # SIGTSTP (suspend)
          "${pc "d"}" = "Ctrl-d"; # EOF
          "${pc "l"}" = "Ctrl-l"; # Clear screen
          "${pc "r"}" = "Ctrl-r"; # Reverse search
          "${pc "a"}" = "Ctrl-a"; # Beginning of line
          "${pc "e"}" = "Ctrl-e"; # End of line
          "${pc "u"}" = "Ctrl-u"; # Kill line before cursor
          "${pc "k"}" = "Ctrl-k"; # Kill line after cursor
          "${pc "w"}" = "Ctrl-w"; # Delete word before cursor
          "${pc "y"}" = "Ctrl-y"; # Yank (paste killed text)
          "${pc "p"}" = "Ctrl-p"; # Previous command
          "${pc "n"}" = "Ctrl-n"; # Next command
          "${pc "f"}" = "Ctrl-f"; # Forward character
          "${pc "b"}" = "Ctrl-b"; # Backward character
          "${pc "t"}" = "Ctrl-t"; # Transpose characters
          "${pc "h"}" = "Ctrl-h"; # Backspace
          "${pc "g"}" = "Ctrl-g"; # Cancel
          "${pc "backslash"}" = "Ctrl-backslash"; # SIGQUIT
        };
    }

    # ════════════════════════════════════════════════════════════════════
    # TEXT NAVIGATION (excludes terminals & file managers)
    # Cmd+Arrow = line/doc, Option+Arrow = word
    # ════════════════════════════════════════════════════════════════════

    {
      name = "Text navigation and editing";
      application.not = terminals ++ fileManagers;
      remap =
        {
          # ── Cmd+Arrow: Line/Document navigation ──
          "${c "Left"}" = "Home";
          "${c "Right"}" = "End";
          "${c "Up"}" = "Ctrl-Home";
          "${c "Down"}" = "Ctrl-End";

          # ── Cmd+Shift+Arrow: Line/Document selection ──
          "${cs "Left"}" = "Shift-Home";
          "${cs "Right"}" = "Shift-End";
          "${cs "Up"}" = "Ctrl-Shift-Home";
          "${cs "Down"}" = "Ctrl-Shift-End";

          # ── Option+Arrow: Word/Paragraph navigation ──
          "${o "Left"}" = "Ctrl-Left";
          "${o "Right"}" = "Ctrl-Right";
          "${o "Up"}" = "Ctrl-Up";
          "${o "Down"}" = "Ctrl-Down";

          # ── Option+Shift+Arrow: Word selection ──
          "${os "Left"}" = "Ctrl-Shift-Left";
          "${os "Right"}" = "Ctrl-Shift-Right";
          "${os "Up"}" = "Ctrl-Shift-Up";
          "${os "Down"}" = "Ctrl-Shift-Down";

          # ── Delete shortcuts ──
          "${o "Backspace"}" = "Ctrl-Backspace"; # Option+Backspace = delete word left
          "${c "Backspace"}" = [
            "Shift-Home"
            "Backspace"
          ]; # Cmd+Backspace = delete to line start
          "${o "Delete"}" = "Ctrl-Delete"; # Option+Delete = delete word right
          "${c "Delete"}" = [
            "Shift-End"
            "Delete"
          ]; # Cmd+Delete = delete to line end
        }
        // lib.optionalAttrs isAltCmd {
          # ── Emacs-style shortcuts (Physical Ctrl → Super after modmap) ──
          "${pc "a"}" = "Home"; # Ctrl+A = line start
          "${pc "e"}" = "End"; # Ctrl+E = line end
          "${pc "k"}" = [
            "Shift-End"
            "Ctrl-x"
          ]; # Ctrl+K = kill to end of line
          "${pc "d"}" = "Delete"; # Ctrl+D = forward delete
          "${pc "h"}" = "Backspace"; # Ctrl+H = backward delete
          "${pc "f"}" = "Right"; # Ctrl+F = forward character
          "${pc "b"}" = "Left"; # Ctrl+B = backward character
          "${pc "p"}" = "Up"; # Ctrl+P = previous line
          "${pc "n"}" = "Down"; # Ctrl+N = next line
        };
    }

    # ════════════════════════════════════════════════════════════════════
    # BROWSER SHORTCUTS
    # ════════════════════════════════════════════════════════════════════

    {
      name = "Browser shortcuts";
      application.only = browsers;
      remap = {
        # Cmd+[ / ] = back / forward
        "${c "leftbrace"}" = "Alt-Left";
        "${c "rightbrace"}" = "Alt-Right";
        # Cmd+Shift+[ / ] = prev / next tab
        "${cs "leftbrace"}" = "Ctrl-PageUp";
        "${cs "rightbrace"}" = "Ctrl-PageDown";
      };
    }

    # ════════════════════════════════════════════════════════════════════
    # FILE MANAGER SHORTCUTS (Finder-style)
    # ════════════════════════════════════════════════════════════════════

    {
      name = "File manager shortcuts";
      application.only = fileManagers;
      remap = {
        "${c "Up"}" = "Alt-Up"; # Cmd+Up = parent folder
        "${c "Down"}" = "Enter"; # Cmd+Down = open selected
        "${c "leftbrace"}" = "Alt-Left"; # Cmd+[ = back
        "${c "rightbrace"}" = "Alt-Right"; # Cmd+] = forward
        "${c "i"}" = "Alt-Enter"; # Cmd+I = properties
        "${c "Backspace"}" = "Delete"; # Cmd+Backspace = trash
        "${c "y"}" = "Space"; # Cmd+Y = Quick Look
      };
    }

    # ════════════════════════════════════════════════════════════════════
    # VS CODE / CURSOR
    # ════════════════════════════════════════════════════════════════════

    {
      name = "VS Code and Cursor";
      application.only = codeEditors;
      remap = {
        "${cs "k"}" = "Ctrl-Shift-k"; # Cmd+Shift+K = delete line
        "${c "d"}" = "Ctrl-d"; # Cmd+D = select word / add next match
        "${cs "l"}" = "Ctrl-Shift-l"; # Cmd+Shift+L = select all occurrences
        "${cs "slash"}" = "Ctrl-Shift-a"; # Cmd+Shift+/ = block comment
        "${c "leftbrace"}" = "Ctrl-leftbrace"; # Cmd+[ = outdent
        "${c "rightbrace"}" = "Ctrl-rightbrace"; # Cmd+] = indent
        "${o "Left"}" = "Ctrl-Left"; # Option+Arrow = word navigation
        "${o "Right"}" = "Ctrl-Right";
      };
    }

    # ════════════════════════════════════════════════════════════════════
    # JETBRAINS IDEs
    # ════════════════════════════════════════════════════════════════════

    {
      name = "JetBrains IDEs";
      application.only = jetbrainsIdes;
      remap = {
        "${o "Left"}" = "Ctrl-Left"; # Option+Arrow = word navigation
        "${o "Right"}" = "Ctrl-Right";
        "${os "Left"}" = "Ctrl-Shift-Left";
        "${os "Right"}" = "Ctrl-Shift-Right";
      };
    }
  ];

in
{
  virtual_modifiers = lib.optionals (!isAltCmd) [ "F20" ];
  modmap = extraModmap ++ modmap;
  keymap = keymap ++ extraKeymap;
}
