{
  # Display manager default session configuration for cody
  # Sets the default desktop session to gnome
  cody.display-session = {
    nixos = { config, lib, ... }:
      lib.mkIf config.services.displayManager.enable {
        services.displayManager.defaultSession = "gnome";
      };
  };
}

