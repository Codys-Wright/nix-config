{
  options,
  config,
  pkgs,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.system.boot.systemd-boot;
in
{
  options.${namespace}.system.boot.systemd-boot = with types; {
    enable = mkBoolOpt false "Whether or not to enable systemd-booting.";
  };

  config = mkIf cfg.enable {
    boot.loader = {
      systemd-boot = {
        enable = true;

        configurationLimit = 5;
        editor = false;
      };
      efi.canTouchEfiVariables = true;

      timeout = 5;
    };
  };
}
