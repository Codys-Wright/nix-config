# System password configuration aspect
# Works with den's user context system to set user passwords
{
  den,
  lib,
  FTS,
  __findFile,
  ...
}:
let
  description = ''
    System password configuration that works with den user context.

    Can be used to set passwords for users defined in den.hosts.*.users.* = { };

    Example usage:
      <FTS.user/password> { method = "initial"; value = "changeme"; }
      # Sets initial password for all users on the host

    Methods:
    - initial: Sets initial password (user must change on first login)
    - hashed: Sets pre-hashed password
    - none: No password authentication (key-based auth only)
  '';

  # Configure password for a specific user
  userPasswordContext =
    { user, ... }:
    arg:
    let
      config =
        if lib.isAttrs arg then
          arg
        else
          {
            method = "initial";
            value = "password";
          };
      method = config.method or "initial";
      value = config.value or "password";
    in
    {
      nixos.users.users.${user.userName} = lib.mkMerge [
        (lib.optionalAttrs (method == "initial") {
          initialPassword = value;
        })
        (lib.optionalAttrs (method == "hashed") {
          hashedPassword = value;
        })
        (lib.optionalAttrs (method == "none") {
          # Remove password authentication entirely
          password = "!";
          hashedPassword = null;
        })
      ];
    };

  # Default password for fallback nixos user
  defaultPasswordContext =
    { host, ... }:
    arg:
    lib.mkIf (host.users or { } == { }) (
      let
        config =
          if lib.isAttrs arg then
            arg
          else
            {
              method = "initial";
              value = "nixos";
            };
        method = config.method or "initial";
        value = config.value or "nixos";
      in
      {
        nixos.users.users.nixos = lib.mkMerge [
          (lib.optionalAttrs (method == "initial") {
            initialPassword = value;
          })
          (lib.optionalAttrs (method == "hashed") {
            hashedPassword = value;
          })
          (lib.optionalAttrs (method == "none") {
            password = "!";
            hashedPassword = null;
          })
        ];
      }
    );
  # Build a password config from functor args.
  mkPasswordConfig =
    arg:
    if arg == null then
      {
        method = "initial";
        value = "password";
      }
    else if lib.isAttrs arg then
      {
        method = arg.method or "initial";
        value = arg.value or "password";
      }
    else
      {
        method = "initial";
        value = toString arg;
      };
in
{
  # Usage: (<FTS.user/password> { method = "initial"; value = "changeme"; })
  FTS.user._.password.__functor =
    _self: arg:
    let
      config = mkPasswordConfig arg;
    in
    <den.lib.parametric> {
      inherit description;
      includes = [
        ({ user, ... }: userPasswordContext { inherit user; } config)
        ({ host, ... }: defaultPasswordContext { inherit host; } config)
      ];
    };
}
