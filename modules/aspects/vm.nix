# VM aspect - provides virtualisation.vmVariant and VM image generation for systems
# Ensures VM variant inherits host configuration with virtualization enabled
top@{ inputs, den, lib, ... }:
{
  flake-file.inputs.nixos-generators.url = "github:nix-community/nixos-generators";
  flake-file.inputs.nixos-generators.inputs.nixpkgs.follows = "nixpkgs";

  den.provides.vm =
    { ... }:
    {
      # nixos-generators.nixosGenerate handles VM configuration automatically
      # No nixos module needed - perSystem generates the VM packages directly
    };

  perSystem =
    { system, inputs', ... }:
    let
      # Get nixosConfigurations for this system
      # Access top-level inputs via top.inputs
      nixosConfigs = top.inputs.self.nixosConfigurations or {};
      systemConfigs = lib.filterAttrs
        (name: config: config.pkgs.system == system)
        nixosConfigs;
      
      # Generate VMs for all configs that include the VM aspect
      # Since we're using nixos-generators.nixosGenerate, we don't need to check for virtualisation.vmVariant
      # We'll generate VMs for all configs - the aspect inclusion determines if a VM should be built
      vmConfigs = systemConfigs;
      
      # Generate VM packages using nixos-generators.nixosGenerate
      # This uses the flake-based approach instead of the NixOS module approach
      vmPackages = lib.mapAttrs'
        (name: config: lib.nameValuePair "${name}-vm"
          (top.inputs.nixos-generators.nixosGenerate {
            system = builtins.currentSystem or system;
            modules = config._module.args.modules;
            format = "vm-bootloader";
          })
        )
        vmConfigs;
    in
    {
      packages = vmPackages;
      
      # Add apps so we can run VMs with `nix run .#dave-vm`
      # Use the same name as the package (e.g., "dave-vm")
      # The format output has run-nixos-vm in the bin/ directory
      apps = lib.mapAttrs'
        (packageName: vmPackage: lib.nameValuePair packageName
          {
            type = "app";
            program = "${vmPackage}/bin/run-nixos-vm";
          }
        )
        vmPackages;
    };
}
