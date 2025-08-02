{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.system.disk;
in
{
  options.${namespace}.system.disk = {
    enable = mkBoolOpt false "Enable disko disk management";
    
    type = mkOption {
      type = types.enum [ "simple" "btrfs" "btrfs-impermanence" "btrfs-luks-impermanence" ];
      default = "simple";
      description = "Type of disk configuration to use";
    };
    
    device = mkOption {
      type = types.str;
      default = "/dev/sda";
      description = "Disk device to configure";
    };
    
    withSwap = mkBoolOpt false "Enable swap partition";
    
    swapSize = mkOption {
      type = types.str;
      default = "8";
      description = "Swap size in GB";
    };
    
    persistFolder = mkOption {
      type = types.str;
      default = "/persist";
      description = "Folder to persist data for impermanence configurations";
    };
  };

  config = mkIf cfg.enable {
    # Import the appropriate disk configuration based on type
    disko.devices = 
      if cfg.type == "simple" then
        (import ./simple-disk.nix { inherit lib; device = cfg.device; }).disko.devices
      else if cfg.type == "btrfs" then
        (import ./btrfs-disk.nix { inherit lib; device = cfg.device; withSwap = cfg.withSwap; swapSize = cfg.swapSize; }).disko.devices
      else if cfg.type == "btrfs-impermanence" then
        (import ./btrfs-impermanence-disk.nix { inherit lib; device = cfg.device; withSwap = cfg.withSwap; swapSize = cfg.swapSize; persistFolder = cfg.persistFolder; }).disko.devices
      else if cfg.type == "btrfs-luks-impermanence" then
        (import ./btrfs-luks-impermanence-disk.nix { 
          inherit lib; 
          device = cfg.device; 
          withSwap = cfg.withSwap;
          swapSize = cfg.swapSize;
          persistFolder = cfg.persistFolder;
        }).disko.devices
      else
        throw "Unknown disk type: ${cfg.type}";
    
    # Add additional packages for LUKS configurations
    environment.systemPackages = mkIf (cfg.type == "btrfs-luks-impermanence") [
      pkgs.yubikey-manager
    ];
  };
}
