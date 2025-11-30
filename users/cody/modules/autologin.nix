{
  # Autologin configuration for cody (useful for VM testing)
  # Automatically logs in cody when display manager is enabled
  cody.autologin =
    { user, ... }:
    {
      nixos =
        { config, lib, ... }:
        lib.mkIf config.services.displayManager.enable {
          services.displayManager.autoLogin = {
            enable = true;
            user = user.userName;
          };
        };
    };
}

