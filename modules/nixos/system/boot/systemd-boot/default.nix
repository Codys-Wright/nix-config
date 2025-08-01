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
    quiet-boot = mkBoolOpt false "Enable quiet boot with reduced logging and Plymouth splash screen";
  };

  config = mkIf cfg.enable {
    boot = {
      loader = {
        systemd-boot = {
          enable = true;

          configurationLimit = 5;
          editor = false;
        };
        efi.canTouchEfiVariables = true;

        timeout = 5;
      };

      # Quiet boot configuration
      plymouth = mkIf cfg.quiet-boot {
        enable = true;
      };
      
      # Reduce initrd verbosity
      initrd.verbose = mkIf cfg.quiet-boot false;
      
      # Kernel parameters for quiet boot
      kernelParams = mkIf cfg.quiet-boot [
        "quiet"
        "splash"
        "boot.shell_on_fail"
        "loglevel=3"
        "rd.systemd.show_status=false"
        "rd.udev.log_level=3"
        "udev.log_priority=3"
      ];
    };
  };
}
