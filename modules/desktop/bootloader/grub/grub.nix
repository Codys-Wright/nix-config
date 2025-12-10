
{
  inputs,
  den,
  lib,
  FTS,
  ...
}:
{
  FTS.grub = {
    description = "GRUB boot loader configuration for NixOS";

    nixos = { config, pkgs, lib, ... }:
    let
      inherit (lib) mkIf mkEnableOption mkOption types;
      cfg = config.FTS.grub;
      # Automatically use device from FTS.disk if available, otherwise use configured device
      grubDevice = if cfg.device != null then cfg.device
        else if config.FTS.disk.enable or false then config.FTS.disk.device
        else null;
      grubDevices = if cfg.devices != [] then cfg.devices
        else if grubDevice != null then [ grubDevice ]
        else [];
    in
    {
      options.FTS.grub = {
        enable = mkOption {
          type = types.bool;
          default = true;  # Enabled by default when aspect is included
          description = "Enable GRUB boot loader";
        };

        device = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Device to install GRUB to (e.g., /dev/sda or /dev/vda). If null and FTS.disk is enabled, will use FTS.disk.device. Set to 'nodev' for UEFI mode.";
        };

        devices = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "List of devices to install GRUB to";
        };

        uefi = mkOption {
          type = types.nullOr types.bool;
          default = true;  # Default to UEFI for all hosts
          description = "Force UEFI mode (true) or BIOS mode (false). If null, auto-detect based on device setting.";
        };

        useOSProber = mkOption {
          type = types.bool;
          default = false;
          description = "Enable OS prober to detect other operating systems";
        };
      };

      config = mkIf cfg.enable (let
        # Determine if we should use UEFI mode
        useUefi = if cfg.uefi != null then cfg.uefi
                  else if grubDevice == "nodev" then true
                  else if grubDevice == null && grubDevices == [] then true
                  else false;
      in {
        boot.loader.grub = lib.mkMerge [
          {
            enable = true;
            useOSProber = cfg.useOSProber;
            efiSupport = lib.mkForce useUefi;
            efiInstallAsRemovable = false;  # Install to EFI system partition
          }
          # For UEFI: use devices = ["nodev"] and don't set device
          (lib.mkIf useUefi {
            devices = lib.mkForce [ "nodev" ];
          })
          # For BIOS: use device = actual device path
          (lib.mkIf (!useUefi) {
            device = lib.mkForce grubDevice;
            devices = lib.mkForce grubDevices;
          })
        ];
        # Enable EFI variable management for UEFI systems
        boot.loader.efi.canTouchEfiVariables = mkIf useUefi true;
      });
    };
  };
}

