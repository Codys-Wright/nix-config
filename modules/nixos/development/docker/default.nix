{ config, lib, pkgs, namespace, ... }:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.development.docker;
  userSettings = config.${namespace}.config.user;
in
{
  options.${namespace}.development.docker = with types; {
    enable = mkBoolOpt false "Enable Docker development tools";
    storageDriver = mkOpt (types.nullOr (types.enum [
      "aufs"
      "btrfs"
      "devicemapper"
      "overlay"
      "overlay2"
      "zfs"
    ])) null "Docker storage driver";
  };

  config = mkIf cfg.enable {
    virtualisation.docker = {
      enable = true;
      enableOnBoot = true;
      storageDriver = cfg.storageDriver;
      autoPrune.enable = true;
    };
    
    users.users.${userSettings.name}.extraGroups = [ "docker" ];
    
    environment.systemPackages = with pkgs; [
      docker
      docker-compose
      lazydocker
    ];
  };
}
