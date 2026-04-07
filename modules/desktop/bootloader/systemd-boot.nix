# systemd-boot bootloader aspect
#
# Usage:
#   <fleet/systemd-boot>
#   (fleet.systemd-boot { configurationLimit = 20; })
{
  fleet,
  ...
}:
{
  fleet.systemd-boot = {
    description = "systemd-boot UEFI bootloader";

    __functor =
      _self:
      {
        configurationLimit ? 15,
      }:
      { class, aspect-chain }:
      {
        nixos =
          { lib, ... }:
          {
            boot.loader.systemd-boot.enable = lib.mkForce true;
            boot.loader.systemd-boot.configurationLimit = configurationLimit;
            boot.loader.efi.canTouchEfiVariables = true;
          };
      };
  };
}
