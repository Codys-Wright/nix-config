# Bluetooth hardware aspect
{
  lib,
  fleet,
  ...
}:
{
  fleet.hardware._.bluetooth = {
    description = "Bluetooth hardware support";

    nixos =
      { pkgs, ... }:
      {
        hardware.bluetooth = {
          enable = true;
          powerOnBoot = true;
        };

        services.blueman.enable = true;

        environment.systemPackages = [ pkgs.librepods ];
      };
  };
}
