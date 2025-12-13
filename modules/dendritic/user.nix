# Parametric provider for user configuration
# Sets up basic user accounts on nixos and darwin
{
  den,
  ...
}:
{
  den.aspects.dendritic.provides.user =
    { user, host, ... }:
    let
      by-class.nixos.users.users.${user.userName}.isNormalUser = true;
      by-class.darwin = {
        system.primaryUser = user.userName;
        users.users.${user.userName} = {
          name = user.userName;
          home = "/Users/${user.userName}";
        };
      };

      # Host-specific overrides can go here if needed
      by-host = { };
    in
    {
      includes = [
        by-class
        (by-host.${host.name} or { })
      ];
    };
}

