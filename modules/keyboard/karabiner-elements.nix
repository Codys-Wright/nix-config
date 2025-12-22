{
  FTS.karabiner-elements = {
    description = "Karabiner-Elements for macOS keyboard customization";

    nixos = {
      # Karabiner-Elements is macOS-specific, not applicable to NixOS
    };

    darwin = {pkgs, ...}: {
      environment.systemPackages = [
        pkgs.karabiner-elements
      ];
    };
  };
}

