{
  FTS.karabiner-elements = {
    description = "Karabiner-Elements for macOS keyboard customization";

    nixos = {
      # Karabiner-Elements is macOS-specific, not applicable to NixOS
    };

    darwin = {pkgs, ...}: {
      environment.systemPackages = [
        #Currently brokem, doesn't enable the right things, install manually for now
        # pkgs.karabiner-elements
        # pkgs.karabiner-dk
      ];
    };
  };
}
