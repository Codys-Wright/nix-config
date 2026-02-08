{
  inputs,
  den,
  lib,
  ...
}:
let
  allowUnfree = true;

  permittedInsecurePackages = [
    "dotnet-runtime-6.0.36" # EOL .NET 6.0 for MelonLoader compatibility
  ];
in
{
  # default.{host,user,home} aspects can be used for global settings.
  den.default = {
    darwin.system.stateVersion = 6;
    nixos.system.stateVersion = "25.11";
    homeManager.home.stateVersion = "25.11";

    # Enable unfree packages across all classes
    nixos.nixpkgs.config = { inherit allowUnfree permittedInsecurePackages; };
    darwin.nixpkgs.config = { inherit allowUnfree; };
    homeManager.nixpkgs.config = { inherit allowUnfree permittedInsecurePackages; };
  };
}
