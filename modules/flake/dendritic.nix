{ inputs, lib, ... }:
{
  # flake-aspects + nixos-generators stay here (no single owning module).
  # flake-file declares its own input (github:denful/flake-file) in its
  # dendritic module, so it is not repeated here.
  flake-file.inputs.flake-aspects.url = lib.mkDefault "github:vic/flake-aspects";
  flake-file.inputs.nixos-generators.url = lib.mkDefault "github:nix-community/nixos-generators";
  flake-file.inputs.nixos-generators.inputs.nixpkgs.follows = "nixpkgs";

  # The platforms this fleet runs (nixpkgs 26.11 dropped x86_64-darwin, and
  # flake-parts' default list still carried it → perSystem eval errors;
  # mkForce because `systems` is a list option that would merge).
  systems = lib.mkForce [
    "x86_64-linux"
    "aarch64-linux"
    "aarch64-darwin"
  ];

  imports = [
    (inputs.flake-file.flakeModules.dendritic)
    (inputs.den.flakeModules.dendritic)
  ];

  flake-file = {
    description = "A flake for Cody's Entire Computing World";
    outputs = lib.mkForce ''
      inputs:
        inputs.flake-parts.lib.mkFlake { inherit inputs; } {
          imports = [
            (inputs.import-tree ./modules)
            (inputs.import-tree ./hosts)
            (inputs.import-tree ./users)
          ];
        }
    '';
  };

}
