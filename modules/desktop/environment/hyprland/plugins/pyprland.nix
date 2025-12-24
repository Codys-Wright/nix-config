# Pyprland - Python plugin system for Hyprland
{FTS, pkgs, ...}: {
  FTS.desktop._.environment._.hyprland._.plugins._.pyprland = {
    description = "Pyprland Python plugin system for Hyprland";

    nixos = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        pyprland
      ];
    };

    homeManager = {
      # Pyprland configuration
      # Currently pyprland doesn't have a dedicated home-manager module
      # Configuration would typically go in ~/.config/hypr/pyprland.toml
      
      home.file.".config/hypr/pyprland.toml".text = ''
        [pyprland]
        plugins = [
          # Add pyprland plugins here
          # Examples: "scratchpads", "magnify", "shift_monitors", etc.
        ]

        # Plugin-specific configurations can be added below
        # [scratchpads.term]
        # command = "kitty --class scratchpad"
        # animation = "fromTop"
      '';
    };
  };
}
