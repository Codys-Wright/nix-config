# xremap — macOS-style keybindings for niri
# Remaps Super+C/V/X/Z/A/S/F/T/W/R/N/P to Ctrl equivalents for apps,
# with terminal-specific overrides (Super+C → Ctrl+Shift+C, etc.)
{
  FTS,
  inputs,
  ...
}:
{
  FTS.desktop._.environment._.niri._.xremap = {
    description = ''
      macOS-style keyboard shortcuts via xremap.
      Maps Super+letter to Ctrl+letter for common app shortcuts (copy, paste,
      undo, save, find, etc.) while preserving Super as niri's Mod key for
      window management. Terminal apps get Ctrl+Shift variants for copy/paste.
    '';

    homeManager =
      { ... }:
      {
        imports = [ inputs.xremap-flake.homeManagerModules.default ];

        services.xremap = {
          enable = true;
          withNiri = true;
          config = {
            keymap = [
              # Terminal overrides — must come first (first match wins)
              {
                name = "Terminal copy/paste";
                application = {
                  only = [
                    "kitty"
                    "ghostty"
                    "foot"
                    "Alacritty"
                    "org.wezfurlong.wezterm"
                  ];
                };
                remap = {
                  "Super-c" = "Ctrl-Shift-c";
                  "Super-v" = "Ctrl-Shift-v";
                };
              }
              # Global macOS-style shortcuts
              {
                name = "macOS-style shortcuts";
                remap = {
                  "Super-c" = "Ctrl-c";
                  "Super-v" = "Ctrl-v";
                  "Super-x" = "Ctrl-x";
                  "Super-z" = "Ctrl-z";
                  "Super-Shift-z" = "Ctrl-Shift-z";
                  "Super-a" = "Ctrl-a";
                  "Super-s" = "Ctrl-s";
                  "Super-f" = "Ctrl-f";
                  "Super-t" = "Ctrl-t";
                  "Super-w" = "Ctrl-w";
                  "Super-r" = "Ctrl-r";
                  "Super-n" = "Ctrl-n";
                  "Super-p" = "Ctrl-p";
                };
              }
            ];
          };
        };
      };
  };
}
