{ ... }:
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
