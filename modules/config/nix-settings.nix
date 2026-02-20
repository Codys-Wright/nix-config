{
  FTS,
  den,
  __findFile,
  ...
}:
let
  nixSettings =
    { config, lib, ... }:
    {
      nix = {
        optimise.automatic = true;
        settings = {
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          trusted-users = [
            "root"
            "@wheel"
          ];
          substituters = [
            "https://cache.nixos.org/"
          ];
        };
        gc = lib.optionalAttrs config.nix.enable {
          automatic = true;
          options = "--delete-older-than 7d";
        };
      };
    };
in
{
  FTS.nix-settings = {
    description = "Shared nix settings and package policy";
    includes = [
      <FTS/nix>
      (<den/unfree> true)
    ];
    nixos = nixSettings;
    darwin = nixSettings;
  };

  flake.modules.nixos.nixpkgs.config.permittedInsecurePackages = [
    "dotnet-runtime-6.0.36"
  ];
  flake.modules.homeManager.nixpkgs.config.permittedInsecurePackages = [
    "dotnet-runtime-6.0.36"
  ];
}
