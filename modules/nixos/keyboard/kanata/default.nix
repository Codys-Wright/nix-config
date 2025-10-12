{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.FTS-FLEET.keyboard.kanata;
in
{
  options.FTS-FLEET.keyboard.kanata = {
    enable = mkEnableOption "Kanata keyboard remapper";
    
    package = mkOption {
      type = types.package;
      default = pkgs.kanata;
      description = "Kanata package to use";
    };
    
    configFile = mkOption {
      type = types.path;
      default = ./FTS-Kanata-Config.kbd;
      description = "Path to the Kanata configuration file";
    };
    
    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Extra arguments to pass to Kanata";
    };
    
    devices = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Specific devices to target (empty means all devices)";
    };
    
    port = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = "Port number for Kanata daemon";
    };
  };

  config = mkIf cfg.enable {
    services.kanata = {
      enable = true;
      package = cfg.package;
      keyboards.fts-kanata = {
        configFile = cfg.configFile;
        extraArgs = cfg.extraArgs;
        devices = cfg.devices;
        port = cfg.port;
        extraDefCfg = "process-unmapped-keys yes";
      };
    };

    # Add the Kanata service user to necessary groups
    systemd.services.kanata-fts-kanata.serviceConfig = {
      SupplementaryGroups = [
        "input"
        "uinput"
      ];
    };
  };
}
