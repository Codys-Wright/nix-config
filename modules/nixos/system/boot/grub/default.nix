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
      efi.canTouchEfiVariables = false; # Disable since we're using efiInstallAsRemovable

      grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
        useOSProber = true; # Re-enable os-prober for multi-boot support
        # Install as removable media for better compatibility during installation
        efiInstallAsRemovable = true; # Install as removable media
        # Additional options for better compatibility
        forceInstall = true; # Force installation even if EFI variables fail
        enableCryptodisk = true; # Enable crypto disk support for LUKS
        # Try to be more robust during installation
        splashImage = null; # Disable splash to avoid issues
        gfxmodeEfi = "auto"; # Auto-detect graphics mode
        # Make os-prober more robust
        extraConfig = ''
          # Make os-prober more robust
          GRUB_DISABLE_OS_PROBER=false
          GRUB_OS_PROBER_SKIP_LIST=""
        '';
        # Ensure os-prober doesn't break installation
        extraGrubInstallArgs = [ "--no-nvram" ]; # Don't try to modify NVRAM
      };

      timeout = 5;
    };
  };
}
