{
  # Autologin configuration for user (useful for VM testing)
  # Automatically logs in the user when display manager is enabled
  fleet.user._.autologin = {
    description = "Display-manager autologin for the associated user (VM/testing)";
    includes = [
      (
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
        }
      )
    ];
  };
}
