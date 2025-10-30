{ inputs, lib, ... }:
{
  flake-file.inputs.flake-file.url = lib.mkDefault "github:vic/flake-file";
  imports = [
    inputs.flake-file.flakeModules.dendritic
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
