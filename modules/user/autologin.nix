{
  # Autologin configuration for user (useful for VM testing)
  # Automatically logs in the user when display manager is enabled
  FTS.user._.autologin =
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

