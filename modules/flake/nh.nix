# nh aspect - Nix helper tool for managing NixOS/Nix-darwin configurations
{
  FTS,
  ...
}:
{
  FTS.nh = {
    description = "Nix helper tool (nh) for managing NixOS/Nix-darwin configurations";

    os =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.nh ];
      };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.nh ];
      };
  };
}
