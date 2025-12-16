{
  inputs,
  FTS,
  ...
}:
{
  flake-file.inputs.nix-index-database.url = "github:nix-community/nix-index-database";

  FTS.nix._.nix-index = {
    description = "Nix-index for command lookup and comma integration";

    homeManager = {
      imports = [
        inputs.nix-index-database.homeModules.nix-index
      ];

      programs.nix-index.enable = true;
      programs.nix-index.enableFishIntegration = true;
      programs.nix-index-database.comma.enable = true;
    };
  };
}
