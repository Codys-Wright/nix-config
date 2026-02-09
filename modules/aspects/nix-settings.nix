{
  den,
  FTS,
  ...
}:
{
  FTS.nix-settings = {
    description = "Shared nix defaults and package policy";

    includes = [
      <FTS/nix>
      <FTS/experimental-features>
      (<den/unfree> true)
    ];
  };

  flake.modules.nixos.nixpkgs.config.permittedInsecurePackages = [
    "dotnet-runtime-6.0.36"
  ];
  flake.modules.homeManager.nixpkgs.config.permittedInsecurePackages = [
    "dotnet-runtime-6.0.36"
  ];
}
