# Kernel configuration aspect
# Configures kernel 6_17 for NixOS systems
{
  FTS,
  ...
}:
{
  FTS.kernel = {
    description = "Kernel 6_17 configuration";

    nixos = { pkgs, lib, ... }: {
      boot.kernelPackages = lib.mkDefault (
        pkgs.linuxKernel.packages.linux_6_17
      );
    };
  };
}

