{ inputs, lib, ... }:
{
  flake-file.inputs.flake-file.url = lib.mkDefault "github:vic/flake-file";
  flake-file.inputs.flake-aspects.url = lib.mkDefault "github:vic/flake-aspects";
  flake-file.inputs.nixos-generators.url = lib.mkDefault "github:nix-community/nixos-generators";
  flake-file.inputs.nixos-generators.inputs.nixpkgs.follows = "nixpkgs";
  
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
