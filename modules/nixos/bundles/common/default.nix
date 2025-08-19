{
  options,
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.bundles.common;
in
{
  options.${namespace}.bundles.common = with types; {
    enable = mkBoolOpt false "Whether or not to enable common configuration.";
  };

  config = mkIf cfg.enable {
    services = {
      xserver = {
        enable = true;
        excludePackages = [ pkgs.xterm ];
      };
    };

    ${namespace} = {
      config.nix = enabled;

      hardware = {
        audio = enabled;
        networking = enabled;
        nvidia = enabled;
        storage = enabled;
      };

      programs = {
        sops = disabled;
        nix-ld = enabled;
      };

      services = {
        printing = enabled;
        ssh = enabled;
        selfhost.networking.tailscale = enabled;
      };

      system = {
        fonts = enabled;
        locale = enabled;
        phoenix = enabled;
        kernel = enabled;
      };
    };
  };
}
