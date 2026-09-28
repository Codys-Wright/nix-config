# GRUB boot loader configuration aspect
{
  lib,
  fleet,
  ...
}:
let
  # The aspect body, applied to the host's settings (see `settings` below).
  grubFor =
    {
      devices,
      uefi,
      useOSProber,
      mirroredBoots,
      theme,
      ...
    }:
    let
      inherit (lib) mkIf mkMerge optionals;
      # Normalize devices to a list (accept string or list)
      devicesList =
        if lib.isString devices then
          [ devices ]
        else if lib.isList devices then
          devices
        else
          [ ];
      useUefi =
        if uefi != null then
          uefi
        else if devicesList != [ ] && lib.elem "nodev" devicesList then
          true
        else if devicesList == [ ] then
          true # Default to UEFI if no devices specified
        else
          false;
      hasMirroredBoots = mirroredBoots != [ ];
      grubDevices = devicesList;

      # Theme includes
      themeIncludes =
        if theme == "minegrub" then
          [ fleet.grub._.themes._.minegrub ]
        else if theme == "minegrub-world-sel" then
          [ fleet.grub._.themes._.minegrub-world-sel ]
        else if theme == "minegrub-double-menu" then
          [ fleet.grub._.themes._.minegrub-double-menu ]
        else
          [ ];
    in
    {
      includes = themeIncludes;

      nixos =
        { pkgs, lib, ... }:
        {
          boot.loader.grub = lib.mkMerge [
            {
              enable = true;
              useOSProber = useOSProber;
              efiSupport = lib.mkForce useUefi;
            }
            # Use mirrored boots if configured (e.g., for ZFS with mirrored root pools)
            (lib.mkIf hasMirroredBoots {
              mirroredBoots = lib.mkForce mirroredBoots;
              # For mirrored boots with UEFI, use efiInstallAsRemovable (canTouchEfiVariables must be false)
              efiInstallAsRemovable = lib.mkIf useUefi true;
            })
            # For UEFI without mirrored boots: use devices = ["nodev"] and canTouchEfiVariables
            (lib.mkIf (useUefi && !hasMirroredBoots) {
              devices = lib.mkForce [ "nodev" ];
              efiInstallAsRemovable = false; # Use canTouchEfiVariables instead
            })
            # For BIOS: use devices = list of device paths
            (lib.mkIf (!useUefi && !hasMirroredBoots) {
              devices = lib.mkForce grubDevices;
            })
          ];
          # Enable EFI variable management for UEFI systems (only when not using efiInstallAsRemovable)
          # efiInstallAsRemovable and canTouchEfiVariables are mutually exclusive
          boot.loader.efi.canTouchEfiVariables = mkIf useUefi (
            if hasMirroredBoots then (lib.mkForce false) else (lib.mkForce true)
          );
        };
    };
in
{
  # Per-host knobs: den.hosts.<sys>.<host>.settings.grub.* (modules/den/settings.nix)
  fleet.grub = {
    description = "GRUB boot loader configuration for NixOS";

    settings = {
      devices = lib.mkOption {
        type = lib.types.either lib.types.str (lib.types.listOf lib.types.str);
        default = [ ];
        description = "BIOS install devices (ignored for UEFI)";
      };
      uefi = lib.mkOption {
        type = lib.types.nullOr lib.types.bool;
        default = true;
        description = "UEFI boot (null = infer from devices)";
      };
      useOSProber = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Probe for other operating systems";
      };
      mirroredBoots = lib.mkOption {
        type = lib.types.listOf lib.types.attrs;
        default = [ ];
        description = "boot.loader.grub.mirroredBoots entries (e.g. mirrored ZFS roots)";
      };
      theme = lib.mkOption {
        type = lib.types.nullOr (
          lib.types.enum [
            "minegrub"
            "minegrub-world-sel"
            "minegrub-double-menu"
          ]
        );
        default = null;
        description = "GRUB theme";
      };
    };

    includes = [ ({ host, ... }: grubFor host.settings.grub) ];
  };
}
