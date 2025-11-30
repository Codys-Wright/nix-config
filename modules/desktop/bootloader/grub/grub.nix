
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
        enable = mkEnableOption "GRUB boot loader";

        device = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Device to install GRUB to (e.g., /dev/sda or /dev/vda). If null and FTS.disk is enabled, will use FTS.disk.device";
        };

        devices = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "List of devices to install GRUB to";
        };

        useOSProber = mkOption {
          type = types.bool;
          default = false;
          description = "Enable OS prober to detect other operating systems";
        };
      };

      config = mkIf cfg.enable {
        boot.loader.grub = {
          enable = true;
          device = grubDevice;
          devices = grubDevices;
          useOSProber = cfg.useOSProber;
        };
      };
    };
  };
}

