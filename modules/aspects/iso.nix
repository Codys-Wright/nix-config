# ISO aspect - provides bootable ISO image generation for systems
top@{ inputs, den, lib, ... }:
{
  flake-file.inputs.nixos-generators.url = "github:nix-community/nixos-generators";
  flake-file.inputs.nixos-generators.inputs.nixpkgs.follows = "nixpkgs";

  den.provides.iso =
    { ... }:
    {
      nixos =
        { config, lib, ... }:
        {
          # ISO-specific configuration can go here if needed
        };
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
    in
    {
      packages = lib.mapAttrs'
        (name: config: lib.nameValuePair "${name}-iso"
          (top.inputs.nixos-generators.nixosGenerate {
            system = builtins.currentSystem or system;
            modules = config._module.args.modules;
            format = "install-iso-hyperv";
          })
        )
        systemConfigs;
    };
}
