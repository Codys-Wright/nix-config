# System configuration wrapper aspect
# Combines user, password, and system settings into a unified configuration
{
  den,
  lib,
  FTS,
  __findFile,
  ...
}:
let
  description = ''
    Unified system configuration aspect combining user, password, and system settings.

    Can optionally take parameters for complete system setup:
      FTS.config {
        user = { username = "alice"; isNormalUser = true; };
        password = { method = "initial"; value = "changeme"; };
        system = { hostname = "myhost"; timezone = "America/New_York"; };
      }

    Or use individual components:
      FTS.config { user = { username = "bob"; }; }
      FTS.config { password = { method = "hashed"; value = "$6$..."; }; }
      FTS.config { system = { hostname = "server"; }; }

    Provides a convenient way to configure all basic system settings.
  '';

  # Extract configuration from arguments
  getConfig =
    arg:
    if arg == null || arg == { } then
      {
        user = null;
        password = null;
        system = null;
      }
    else if lib.isAttrs arg then
      {
        user = arg.user or null;
        password = arg.password or null;
        system = arg.system or null;
      }
    else
      throw "config: argument must be an attribute set";
in
{
  FTS.config = <den.lib.parametric> {
    inherit description;
    includes = [
      (
        { nixos, ... }:
        arg:
        let
          config = getConfig arg;
        in
        [
          # Include user configuration if specified
          (lib.optional (config.user != null) ({ nixos, ... }: (FTS.user config.user).includes nixos))

          # Include password configuration if specified
          (lib.optional (config.password != null) (
            { nixos, ... }: (FTS.user._.password config.password).includes nixos
          ))

          # Include system configuration if specified
          (lib.optional (config.system != null) ({ nixos, ... }: (FTS.system config.system).includes nixos))
        ]
      )
    ];
  };
}
