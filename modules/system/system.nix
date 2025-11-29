# General system configuration aspect
# Provides basic system settings like hostname, timezone, locale, etc.
{
  den,
  lib,
  FTS,
  ...
}:
let
  description = ''
    General system configuration for basic OS settings.

    Can optionally take parameters for system configuration:
      FTS.system { hostname = "myhost"; timezone = "America/New_York"; }
      FTS.system {
        hostname = "server";
        timezone = "UTC";
        locale = "en_US.UTF-8";
        defaultLocale = "en_US.UTF-8";
        autoLoginUser = "alice";
      }

    Configures basic system properties for NixOS systems.
  '';

  # Extract system configuration from arguments
  getSystemConfig = arg:
    if arg == null || arg == { } then
      {
        hostname = "nixos";
        timezone = "UTC";
        locale = "en_US.UTF-8";
        defaultLocale = "en_US.UTF-8";
        autoLoginUser = null;
      }
    else if lib.isAttrs arg then
      {
        hostname = arg.hostname or "nixos";
        timezone = arg.timezone or "UTC";
        locale = arg.locale or "en_US.UTF-8";
        defaultLocale = arg.defaultLocale or arg.locale or "en_US.UTF-8";
        autoLoginUser = arg.autoLoginUser or null;
      }
    else
      throw "system: argument must be an attribute set";

  # Configure system settings
  configureSystem = config: nixos: lib.mkMerge [
    {
      # Basic system configuration
      networking.hostName = config.hostname;

      time.timeZone = config.timezone;

      i18n = {
        inherit (config) defaultLocale;
        supportedLocales = [ "${config.locale}/UTF-8" ];
      };

      # Auto-login configuration (if specified)
      services.displayManager.autoLogin = lib.mkIf (config.autoLoginUser != null) {
        enable = true;
        user = config.autoLoginUser;
      };
    }
    nixos
  ];
in
{
  FTS.system = den.lib.parametric {
    inherit description;
    includes = [
      ({ nixos, ... }: arg:
        let
          config = getSystemConfig arg;
        in
        configureSystem config nixos
      )
    ];
  };
}
