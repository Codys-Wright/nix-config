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
  cfg = config.${namespace}.system.boot.grub;
in
{
  options.${namespace}.system.boot.grub = with types; {
    enable = mkBoolOpt false "Whether or not to enable grub booting.";
  };

  config = mkIf cfg.enable {
    boot.loader = {
      # EFI configuration
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot/efi";
      };

      grub = {
        enable = true;
        # Use nodev for UEFI systems
        device = "nodev";
        efiSupport = true;
        # Disable os-prober to avoid installation issues
        useOSProber = false;
        # Install as removable media for better compatibility
        efiInstallAsRemovable = true;
        # Force installation
        forceInstall = true;
        # Enable crypto disk support for LUKS
        enableCryptodisk = true;
        # Disable splash to avoid issues
        splashImage = null;
        # Auto-detect graphics mode
        gfxmodeEfi = "auto";
        # Minimal configuration to avoid blkid issues
        extraConfig = ''
          GRUB_DISABLE_OS_PROBER=true
          GRUB_TIMEOUT=5
          GRUB_TIMEOUT_STYLE=menu
        '';
        # Minimal installation arguments
        extraGrubInstallArgs = [
          "--no-nvram"
          "--removable"
        ];
      };

      timeout = 5;
    };
  };
}
