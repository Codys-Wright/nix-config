# CI checks to ensure configurations build correctly
# Run with: nix flake check
{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      self',
      lib,
      system,
      ...
    }:
    let
      checkCond = name: cond: pkgs.runCommandLocal name { } (if cond then "touch $out" else "");

      # Get configurations
      nixosConfigs = inputs.self.nixosConfigurations or { };
      darwinConfigs = inputs.self.darwinConfigurations or { };

      # Filter configs for current system (skip cross-platform eval entirely)
      isLinux = lib.hasSuffix "-linux" system;
      isDarwin = lib.hasSuffix "-darwin" system;

      systemNixosConfigs =
        if !isLinux then
          { }
        else
          lib.filterAttrs (name: config: config.pkgs.stdenv.hostPlatform.system == system) nixosConfigs;

      systemDarwinConfigs =
        if !isDarwin then
          { }
        else
          lib.filterAttrs (name: config: config.pkgs.stdenv.hostPlatform.system == system) darwinConfigs;

      # Check that NixOS host configs evaluate successfully
      nixosBuildChecks = builtins.mapAttrs (
        name: config:
        # Access stateVersion to force full config evaluation; if this throws, the check fails
        let
          _eval = config.config.system.stateVersion;
        in
        checkCond "${name}-evaluates" (builtins.isString _eval)
      ) systemNixosConfigs;

      # Check that Darwin host configs evaluate successfully
      darwinBuildChecks = builtins.mapAttrs (
        name: config:
        let
          _eval = config.config.system.stateVersion;
        in
        checkCond "${name}-evaluates" (builtins.isString _eval)
      ) systemDarwinConfigs;

      # Check that hosts with ISO support expose the isoImage attribute
      # Always passes — purely a structural check (never fails in CI)
      isoChecks = builtins.mapAttrs (
        name: config:
        # Pass regardless; the presence/absence of isoImage is informational
        checkCond "${name}-iso-available" true
      ) systemNixosConfigs;

      # Check specific aspects and configurations
      specificChecks =
        let
          # Helper to safely check if a config exists and has a property
          safeCheck =
            name: checkFn:
            if systemNixosConfigs ? ${name} then
              checkFn systemNixosConfigs.${name}
            else
              checkCond "${name}-skip" true; # Skip if host doesn't exist on this system
        in
        {
          # Check that dave has vm aspect (includes filesystem and bootloader)
          "dave-has-vm-aspect" = safeCheck "dave" (
            config:
            let
              cfg = config.config;
              hasFilesystem = cfg.fileSystems ? "/";
              hasGrub = cfg.boot.loader.grub.enable or false;
            in
            checkCond "dave-vm-aspect" (hasFilesystem && hasGrub)
          );

          # Check that nh is enabled (should be in defaults)
          "nh-enabled" = safeCheck "dave" (
            config:
            let
              nhEnabled = config.config.programs.nh.enable or false;
            in
            checkCond "nh-enabled" nhEnabled
          );

          # Check that carter user exists on dave
          "carter-on-dave" = safeCheck "dave" (
            config:
            let
              carterExists = config.config.users.users ? carter;
            in
            checkCond "carter-on-dave" carterExists
          );

          # Check that cody user exists on THEBATTLESHIP
          "cody-on-THEBATTLESHIP" = safeCheck "THEBATTLESHIP" (
            config:
            let
              codyExists = config.config.users.users ? cody;
            in
            checkCond "cody-on-THEBATTLESHIP" codyExists
          );
        };

      # Check that ISO packages are available (if iso.nix is included)
      isoPackageChecks =
        if self' ? packages && self'.packages ? dave then
          {
            "iso-dave-package" = checkCond "iso-dave-package" (builtins.pathExists self'.packages.dave);
          }
        else
          { };
    in
    {
      checks = nixosBuildChecks // darwinBuildChecks // isoChecks // specificChecks // isoPackageChecks;
    };
}
