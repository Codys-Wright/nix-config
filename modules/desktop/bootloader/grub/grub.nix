
{
  inputs,
  den,
  lib,
  ...
}:
{
  den.aspects.grub = {
    description = "GRUB boot loader configuration for NixOS";

    nixos = { config, pkgs, lib, ... }:
    let
      inherit (lib) mkIf mkEnableOption mkOption types;
      cfg = config.den.aspects.grub;
    in
    {
      options.den.aspects.grub = {
        enable = mkEnableOption "GRUB boot loader";

        device = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Device to install GRUB to (e.g., /dev/sda or /dev/vda)";
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
          device = cfg.device;
          devices = if cfg.devices != [] then cfg.devices else (if cfg.device != null then [ cfg.device ] else []);
          useOSProber = cfg.useOSProber;
        };
      };
    };
  };
}

