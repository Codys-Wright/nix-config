# System configuration wrapper aspect
# Combines user, password, and system settings into a unified configuration
{
  den,
  lib,
  ...
}:
let
  description = ''
    Unified system configuration aspect combining user, password, and system settings.

    Can optionally take parameters for complete system setup:
      den.aspects.config {
        user = { username = "alice"; isNormalUser = true; };
        password = { method = "initial"; value = "changeme"; };
        system = { hostname = "myhost"; timezone = "America/New_York"; };
      }

    Or use individual components:
      den.aspects.config { user = { username = "bob"; }; }
      den.aspects.config { password = { method = "hashed"; value = "$6$..."; }; }
      den.aspects.config { system = { hostname = "server"; }; }

    Provides a convenient way to configure all basic system settings.
  '';

  # Extract configuration from arguments
  getConfig = arg:
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
  den.aspects.config = den.lib.parametric {
    inherit description;
    includes = [
      ({ nixos, ... }: arg:
        let
          config = getConfig arg;
        in
        [
          # Include user configuration if specified
          (lib.optional (config.user != null)
            ({ nixos, ... }: (den.aspects.user config.user).includes nixos))

          # Include password configuration if specified
          (lib.optional (config.password != null)
            ({ nixos, ... }: (den.aspects.password config.password).includes nixos))

          # Include system configuration if specified
          (lib.optional (config.system != null)
            ({ nixos, ... }: (den.aspects.system config.system).includes nixos))
        ]
      )
    ];
  };
}
