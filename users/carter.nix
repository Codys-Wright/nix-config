{ FTS, ... }:
{
  # Darwin (macOS) home configuration
  den.homes.aarch64-darwin.carter = {
    userName = "electric";
    aspect = "developer";
  };

  # NixOS home configuration
  den.homes.x86_64-linux.carter = {
    userName = "carter";
    aspect = "developer";
  };

  # aspect for each host that includes the user carter.
  FTS.carter.provides.hostUser =
        { user, ... }:
        {
          # administrator in all nixos hosts
          nixos.users.users.${user.userName} = {
            isNormalUser = true;
            extraGroups = [ "wheel" ];
          };
          # darwin configuration
          darwin.system.primaryUser = user.userName;
        };

      # Password configuration for carter
  FTS.carter.provides.password =
        { user, ... }:
        {
          nixos.users.users.${user.userName} = {
            initialPassword = "password"; # TODO: Change this to a hashed password in production
          };
        };

      # Autologin configuration for carter (useful for VM testing)
  FTS.carter.provides.autologin =
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
