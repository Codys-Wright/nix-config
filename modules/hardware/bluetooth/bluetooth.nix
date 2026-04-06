# Bluetooth hardware aspect
{
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
          package = pkgs.bluez;
          powerOnBoot = true;
        };

        services.blueman.enable = true;

        environment.systemPackages = [ pkgs.librepods ];
      };
  };
}
