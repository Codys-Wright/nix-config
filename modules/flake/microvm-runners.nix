# Expose microvm runners as runnable packages
# Usage: nix run .#THEBATTLESHIP-vm
{ inputs, lib, ... }:
{
  perSystem =
    { system, ... }:
    lib.optionalAttrs (system == "x86_64-linux") {
      packages.THEBATTLESHIP-vm =
        inputs.self.nixosConfigurations.THEBATTLESHIP-vm.config.microvm.declaredRunner;
    };
}
