# GRUB boot loader configuration aspect
# Takes named parameters for boot configuration
{
  lib,
  FTS,
  ...
}:
{
  FTS.grub.description = "GRUB boot loader configuration for NixOS";

  # Function that produces a GRUB boot loader configuration aspect
  # Takes named parameters: { devices, uefi, useOSProber, mirroredBoots, ... }
  # Usage: (FTS.grub { uefi = true; })
  FTS.grub.__functor =
    _self:
    {
      devices ? [],
      uefi ? true,
      useOSProber ? false,
      mirroredBoots ? [],
      ...
    }@args:
    { class, aspect-chain }:
    let
      inherit (lib) mkIf mkMerge optionals;
      # Normalize devices to a list (accept string or list)
      devicesList = if lib.isString devices then [ devices ]
                    else if lib.isList devices then devices
                    else [];
      useUefi = if uefi != null then uefi
                else if devicesList != [] && lib.elem "nodev" devicesList then true
                else if devicesList == [] then true  # Default to UEFI if no devices specified
                else false;
      hasMirroredBoots = mirroredBoots != [];
      grubDevices = devicesList;
    in
    {
      includes = [ ];

      nixos = { pkgs, lib, ... }:
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
              efiInstallAsRemovable = false;  # Use canTouchEfiVariables instead
            })
            # For BIOS: use devices = list of device paths
            (lib.mkIf (!useUefi && !hasMirroredBoots) {
              devices = lib.mkForce grubDevices;
            })
          ];
          # Enable EFI variable management for UEFI systems (only when not using efiInstallAsRemovable)
          # efiInstallAsRemovable and canTouchEfiVariables are mutually exclusive
          boot.loader.efi.canTouchEfiVariables = mkIf useUefi (
            if hasMirroredBoots then (lib.mkForce false)
            else (lib.mkForce true)
          );
        };
    };
}
