# parametric providers for user
{
  den,
  FTS,
  ...
}:
{
  FTS.example.provides.user =
    { user, host }:
    let
      by-class.nixos.users.users.${user.userName}.isNormalUser = true;
      by-class.darwin = {
        system.primaryUser = user.userName;
        users.users.${user.userName}.isNormalUser = true;
      };

      # adelie is nixos-on-wsl, has special additional user setup
      by-host.outrider.nixos.defaultUser = user.userName;
    in
    {
      includes = [
        by-class
        (by-host.${host.name} or { })
      ];
    };
}

