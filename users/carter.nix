{ ... }:
{
  den.homes.aarch64-darwin.cody = {
    userName = "electric";
    aspect = "developer";
  };

  den.aspects = {
  # aspect for each host that includes the user carter.
      carter.provides.hostUser =
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
  };

}
