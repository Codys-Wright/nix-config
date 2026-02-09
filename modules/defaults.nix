{
  inputs,
  den,
  lib,
  ...
}:
{
  # default.{host,user,home} aspects can be used for global settings.
  den.default = {
    # Enable unfree packages
    nixos.nixpkgs.config.allowUnfree = true;
    darwin.nixpkgs.config.allowUnfree = true;
    homeManager.nixpkgs.config.allowUnfree = true;

    # Allow EOL .NET 6.0 for MelonLoader compatibility
    nixos.nixpkgs.config.permittedInsecurePackages = [
      "dotnet-runtime-6.0.36"
    ];
    homeManager.nixpkgs.config.permittedInsecurePackages = [
      "dotnet-runtime-6.0.36"
    ];
  };
}
