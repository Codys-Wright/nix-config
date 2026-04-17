# Apple T2 Mac support (2018-2020 Intel Macs with T2 security chip)
#
# Pulls t2linux-patched kernel + drivers from nixos-hardware's apple-t2 module
# (keyboard, trackpad, touchbar, audio, Wi-Fi/BT, thermals) and wires up the
# t2linux cachix so you are not compiling a custom kernel locally.
#
# Post-install firmware step: Wi-Fi and Bluetooth need blobs extracted from a
# macOS recovery image. See https://wiki.t2linux.org — once blobs are installed,
# flip `hardware.apple-t2.firmware.enable = true` on the host.
#
# Usage: include `<fleet.hardware/apple-t2>` on any T2 Mac host.
{
  inputs,
  fleet,
  ...
}:
{
  flake-file.inputs.nixos-hardware.url = "github:NixOS/nixos-hardware";

  fleet.hardware._.apple-t2 = {
    description = "Apple T2 Mac kernel + drivers (2018-2020 Intel Macs)";

    nixos =
      { lib, ... }:
      {
        imports = [ inputs.nixos-hardware.nixosModules.apple-t2 ];

        hardware.apple-t2.kernelChannel = lib.mkDefault "stable";

        hardware.apple-t2.firmware.enable = lib.mkDefault false;
        hardware.apple-t2.firmware.version = lib.mkDefault "sonoma";

        hardware.apple.touchBar.enable = lib.mkDefault true;

        nix.settings.trusted-substituters = [ "https://t2linux.cachix.org" ];
        nix.settings.trusted-public-keys = [
          "t2linux.cachix.org-1:P733c5Gt1qTcxsm+Bae0renWnT8OLs0u9+yfaK2Bejw="
        ];
      };
  };
}
