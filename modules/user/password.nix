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
    den.lib.parametric {
      inherit description;
      includes = [
        (
          { user, ... }:
          {
            nixos.users.users.${user.userName} = lib.mkMerge (
              lib.lists.optional (method == "initial") { initialPassword = value; }
              ++ lib.lists.optional (method == "hashed") { hashedPassword = value; }
              ++ lib.lists.optional (method == "none") {
                password = "!";
                hashedPassword = null;
              }
            );
          }
        )
      ];
    };
}
