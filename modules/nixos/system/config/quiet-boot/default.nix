{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.system.quiet-boot;
in
{
  options.${namespace}.system.quiet-boot = {
    enable = mkBoolOpt false "Enable quiet boot with reduced logging and Plymouth splash screen";
  };

  config = mkIf cfg.enable {
    boot = {
      # Enable Plymouth for a graphical boot splash
      plymouth.enable = true;
      
      # Reduce initrd verbosity
      initrd.verbose = false;
      
      # Kernel parameters for quiet boot
      kernelParams = [
        "quiet"
        "splash"
        "boot.shell_on_fail"
        "loglevel=3"
        "rd.systemd.show_status=false"
        "rd.udev.log_level=3"
        "udev.log_priority=3"
      ];
    };

    # Reduce systemd logging during boot
    systemd.showStatus = false;
    
    # Reduce console logging
    console = {
      earlySetup = true;
      colors = [
        {
          normal = "green";
          bright = "bright-green";
        }
      ];
    };
  };
} 