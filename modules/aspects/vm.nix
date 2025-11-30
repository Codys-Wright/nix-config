# VM aspect - provides virtualisation.vmVariant and VM image generation for systems
# Ensures VM variant inherits host configuration with virtualization enabled
top@{ inputs, den, lib, ... }:
{
  flake-file.inputs.nixos-generators.url = "github:nix-community/nixos-generators";
  flake-file.inputs.nixos-generators.inputs.nixpkgs.follows = "nixpkgs";

  den.provides.vm =
    { ... }:
    {
      nixos =
        { lib, ... }:
        {
          # VM resources are configured in perSystem when calling nixos-generators
          # Disable services that don't make sense in a VM
          virtualisation.vmVariant = {
            services.btrfs.autoScrub.enable = lib.mkForce false;
          };
        };
    };

  perSystem =
    { system, inputs', pkgs, ... }:
    let
      # Get nixosConfigurations for this system
      # Access top-level inputs via top.inputs (captured in closure)
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
      # We add a module to configure VM resources (cores, memory) directly
      vmPackages = lib.mapAttrs'
        (name: config: lib.nameValuePair "${name}-vm"
          (top.inputs.nixos-generators.nixosGenerate {
            system = builtins.currentSystem or system;
            modules = config._module.args.modules ++ [
              # Add VM resource configuration directly
              ({ lib, ... }: {
                virtualisation = {
                  # Number of CPU cores (default: 1)
                  cores = 16;
                  # Memory size in MB (default: 1024)
                  memorySize = 1024 * 8; # 8GB
                  # QEMU options for better performance and networking
                  # Using user networking with SSH port forwarding
                  # Host port 2222 forwards to guest port 22 (SSH)
                  # Access VM via: ssh -p 2222 root@localhost
                  qemu.options = [
                    "-cpu" "host"
                    # User networking with SSH port forwarding
                    "-netdev" "user,id=net0,hostfwd=tcp::2222-:22"
                    "-device" "virtio-net-pci,netdev=net0"
                  ];
                };
              })
            ];
            format = "vm-bootloader";
          })
        )
        vmConfigs;
    in
    {
      packages = vmPackages;
      
      # Add apps so we can run VMs with `nix run .#dave-vm`
      # The generated script already has the correct cores and memory from the modules we passed
      apps = lib.mapAttrs'
        (name: config:
          let
            packageName = "${name}-vm";
            vmPackage = vmPackages.${packageName};
          in
          lib.nameValuePair packageName
          {
            type = "app";
            # Use the generated script directly - it already has our cores/memory configuration
            program = "${vmPackage}/bin/run-${name}-vm";
          }
        )
        vmConfigs;
    };
}
