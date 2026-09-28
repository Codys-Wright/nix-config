{
  den,
  lib,
  fleet,
  __findFile,
  ...
}:
{
  fleet.user._.password.__functor =
    _self: arg:
    let
      description = ''
        User password configuration that works with den user context.

        Example usage:
          (<fleet.user/password> { method = "initial"; value = "changeme"; })
          (<fleet.user/password> "mypassword")
      '';

      mkPasswordConfig =
        arg:
        if arg == null then
          {
            method = "initial";
            value = "password";
          }
        else if builtins.isAttrs arg then
          {
            method = arg.method or "initial";
            value = arg.value or "password";
          }
        else
          {
            method = "initial";
            value = builtins.toString arg;
          };

      config = mkPasswordConfig arg;
      method = config.method;
      value = config.value;
    in
    {
      inherit description;
      name = "password(${method})";
      # `user` class → users.users.<this user> on every NixOS host they live
      # on (nix-darwin has no password options; macOS owns account auth).
      includes = [
        (
          { host, ... }:
          lib.optionalAttrs ((host.class or null) == "nixos") {
            user =
              lib.optionalAttrs (method == "initial") { initialPassword = value; }
              // lib.optionalAttrs (method == "hashed") { hashedPassword = value; }
              // lib.optionalAttrs (method == "none") {
                password = "!";
                hashedPassword = null;
              };
          }
        )
      ];
    };
}
