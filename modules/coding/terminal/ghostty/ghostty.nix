# Ghostty terminal emulator aspect
{
  FTS, ... }:
{
  FTS.coding._.terminals._.ghostty = {
    description = "Ghostty terminal emulator (Linux only)";

    nixos = { pkgs, ... }: {
      environment.systemPackages = [
        pkgs.ghostty
      ];
    };

    # Ghostty is not available on Darwin (macOS)
    # Use kitty, wezterm, or other terminals on macOS instead
  };
}

