# Desktop facet - Main router for complete desktop environment configuration
# Intelligently sets up desktop environment, display manager, and common settings
{
  FTS,
  lib,
  ...
}:
{
  FTS.desktop.description = ''
    Desktop configuration facet - Complete desktop setup in one call.
    
    Usage examples:
      # Full configuration with theme
      (<FTS/desktop> {
        environment.default = "gnome";
        bootloader = {
          default = "grub";
          grub = { uefi = true; theme = "minegrub"; };
        };
        displayManager.auto = true;
      })
      
      # Minimal - just specify bootloader type (uses defaults)
      (<FTS/desktop> {
        environment.default = "gnome";
        bootloader.default = "grub";
      })
      
      # Configure multiple bootloaders (only default is active)
      (<FTS/desktop> {
        environment.default = "gnome";
        bootloader = {
          default = "grub";
          grub = { uefi = true; theme = "minegrub"; };
          systemd = { timeout = 5; }; # Configured but not active
        };
      })
      
      # Simplest - auto-configures everything
      (<FTS/desktop> { environment.default = "gnome"; })
    
    Direct access to sub-components:
      (<FTS/desktop/environment/gnome> { })
      (<FTS/desktop/bootloader/grub> { uefi = true; })
      (<FTS/desktop/display-manager/gdm> { })
    
    Benefits of attribute set bootloader config:
    - Type-safe: grub.theme only exists under grub config
    - Future-proof: Switch bootloaders without losing config
    - Multi-config: Configure multiple bootloaders simultaneously
  '';

  # Make desktop callable as a complete router
  FTS.desktop.__functor =
    _self:
    {
      environment ? null,
      bootloader ? null,
      displayManager ? { auto = true; },
      ...
    }@args:
    { class, aspect-chain }:
    let
      # Parse environment config
      envDefault = if environment != null then environment.default or null else null;
      
      # Available environments
      availableEnvs = ["gnome" "hyprland" "kde" "xfce"];
      
      # Parse bootloader config (new attribute set style)
      bootloaderDefault = if bootloader != null then bootloader.default or null else null;
      bootloaderGrubConfig = if bootloader != null then bootloader.grub or {} else {};
      bootloaderSystemdConfig = if bootloader != null then bootloader.systemd or {} else {};
      
      # Validate bootloader
      availableBootloaders = ["grub" "systemd"];
      
      # Combined validation (using _ for throwaway validation checks)
      _ = 
        if envDefault != null && !(builtins.elem envDefault availableEnvs) then
          throw "desktop: unknown environment '${envDefault}'. Available: ${builtins.concatStringsSep ", " availableEnvs}"
        else if bootloaderDefault != null && !(builtins.elem bootloaderDefault availableBootloaders) then
          throw "desktop: unknown bootloader '${bootloaderDefault}'. Available: ${builtins.concatStringsSep ", " availableBootloaders}"
        else null;
      
      # Determine if we should include each bootloader
      shouldIncludeGrub = bootloaderDefault == "grub" || bootloaderGrubConfig != {};
      shouldIncludeSystemd = bootloaderDefault == "systemd" || bootloaderSystemdConfig != {};
      
      # Parse display manager config
      dmAuto = if displayManager != null then displayManager.auto or true else true;
      dmType = if displayManager != null then displayManager.type or null else null;
      
      # Auto-select display manager based on desktop environment
      autoDisplayManager = 
        if !dmAuto && dmType != null then dmType
        else if dmType != null then dmType
        else if envDefault == "gnome" then "gdm"
        else if envDefault == "kde" then "sddm"
        else if envDefault == "hyprland" then "gdm"
        else if envDefault == "xfce" then "lightdm"
        else null;
      
      # Build includes
      envIncludes = lib.optionals (envDefault != null) [
        FTS.desktop._.environment._.${envDefault}
      ];
      
      bootloaderIncludes = 
        # Include GRUB if it's the default or explicitly configured
        (lib.optionals shouldIncludeGrub [
          (FTS.grub bootloaderGrubConfig)
        ]) ++
        # Include systemd-boot if it's the default or explicitly configured
        (lib.optionals shouldIncludeSystemd [
          # (FTS.systemd-boot bootloaderSystemdConfig)
          (throw "systemd-boot not yet implemented")
        ]);
      
      dmIncludes = lib.optionals (autoDisplayManager != null) [
        # TODO: Once display-manager is refactored, use:
        # FTS.desktop._.display-manager._.${autoDisplayManager}
        # For now, use old paths:
        (if autoDisplayManager == "gdm" then FTS.gdm
         else if autoDisplayManager == "sddm" then FTS.sddm
         else if autoDisplayManager == "lightdm" then FTS.lightdm
         else throw "Unknown display manager: ${autoDisplayManager}")
      ];
    in
    {
      includes = envIncludes ++ bootloaderIncludes ++ dmIncludes;
    };
}

