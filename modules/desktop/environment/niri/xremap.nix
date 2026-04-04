# xremap — macOS-style keybindings for niri
#
# Uses the mac-keybindings module with cmdKey = "super":
#   Caps Lock (hold) → ISO_Level3_Shift / Mod5 (niri Mod), tap → Escape
#   Esc (hold)       → ISO_Level3_Shift / Mod5 (niri Mod), tap → Escape
#   Right Ctrl       → ISO_Level3_Shift / Mod5 (niri Mod)
#   Right Alt        → ISO_Level3_Shift / Mod5 (niri Mod)
#   Physical Super L → F20 → "Cmd" app shortcuts
#   Physical Super R → Symbols layer (hold + key → symbol)
#   Physical Ctrl    → Ctrl (terminal signals, unchanged)
#   Physical Alt L   → Alt ("Option" word nav)
{
  FTS,
  inputs,
  lib,
  ...
}:
let
  macKeybindings = import ../../mac-keybindings/_mac-keybindings.nix { inherit lib; };

  xremapConfig = macKeybindings {
    cmdKey = "super";

    # Caps Lock / Esc / Right Ctrl → Alt_R (XKB lv3:ralt_switch maps Alt_R → Mod5)
    # Physical Alt_R is omitted — XKB handles it natively as Mod5
    extraModmap = [
      {
        name = "Hyper keys → Mod5 (niri Mod via Alt_R → XKB lv3)";
        remap = {
          CapsLock = {
            tap = "Esc";
            hold = "Alt_R";
            held_threshold_millis = 80;
            tap_timeout_millis = 10000;
          };
          Esc = {
            tap = "Esc";
            hold = "Alt_R";
            held_threshold_millis = 100;
            tap_timeout_millis = 10000;
          };
          Ctrl_R = {
            tap = "Ctrl_R";
            hold = "Alt_R";
            held_threshold_millis = 0;
            tap_timeout_millis = 200;
          };
        };
      }
    ];

    # Symbols layer: hold Right Super + key → symbol
    # Ported from kanata symbols layer (rmet hold)
    extraKeymap = [
      {
        name = "Symbols layer (Right Super held)";
        remap = {
          # ── Left hand: top row ──
          "Super_R-Tab" = "Shift-1"; # !
          "Super_R-q" = "comma"; # ,
          "Super_R-w" = "Shift-leftbrace"; # {
          "Super_R-e" = "Shift-rightbrace"; # }
          "Super_R-r" = "semicolon"; # ;
          "Super_R-t" = "Shift-slash"; # ?

          # ── Left hand: home row ──
          "Super_R-a" = "Shift-6"; # ^
          "Super_R-s" = "equal"; # =
          "Super_R-d" = "Shift-minus"; # _
          "Super_R-f" = "Shift-4"; # $
          "Super_R-g" = "Shift-8"; # *

          # ── Right hand: home row ──
          "Super_R-k" = "apostrophe"; # '
          "Super_R-l" = "Shift-apostrophe"; # "
          "Super_R-semicolon" = "Shift-equal"; # +

          # ── Left hand: bottom row ──
          "Super_R-z" = "Shift-grave"; # ~
          "Super_R-x" = "Shift-comma"; # <
          "Super_R-c" = "Shift-backslash"; # |
          "Super_R-v" = "minus"; # -
          "Super_R-b" = "Shift-dot"; # >

          # ── Right hand: bottom row ──
          "Super_R-n" = "backslash"; # \
          "Super_R-m" = "Shift-5"; # %
          "Super_R-comma" = "Shift-semicolon"; # :
          "Super_R-dot" = "Shift-7"; # &
          "Super_R-slash" = "Shift-comma"; # <

          # ── Number row → brackets/parens/punctuation ──
          "Super_R-1" = "leftbrace"; # [
          "Super_R-2" = "Shift-9"; # (
          "Super_R-3" = "Shift-0"; # )
          "Super_R-4" = "rightbrace"; # ]
          "Super_R-5" = "dot"; # .
          "Super_R-6" = "Shift-5"; # %
          "Super_R-7" = "Shift-6"; # ^
          "Super_R-8" = "Shift-7"; # &
          "Super_R-9" = "Shift-8"; # *
          "Super_R-0" = "Shift-9"; # (

          # ── Passthrough: swallow Super_R so it doesn't leak to WM ──
          "Super_R-y" = "y";
          "Super_R-u" = "u";
          "Super_R-i" = "i";
          "Super_R-o" = "o";
          "Super_R-p" = "p";
          "Super_R-h" = "h";
          "Super_R-j" = "j";
          "Super_R-space" = "space";
          "Super_R-Shift_L" = "Shift_L";
          "Super_R-Backspace" = "Backspace";
          "Super_R-Enter" = "Enter";
        };
      }
    ];
  };
in
{
  FTS.desktop._.environment._.niri._.xremap = {
    description = ''
      macOS-style keyboard shortcuts via xremap.
      Caps Lock (hold) = Mod5 (niri Mod), Physical Super = Cmd (F20 virtual modifier).
    '';

    homeManager =
      { ... }:
      {
        imports = [ inputs.xremap-flake.homeManagerModules.default ];

        services.xremap = {
          enable = true;
          withNiri = true;
          config = xremapConfig;
        };
      };
  };
}
