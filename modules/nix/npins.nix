let
  my.nix._.npins = {
    os = npins-system;
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.npins ];
      };
  };

  npins-system =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.npins ];
    };
in
{
  # npins aspect - Pin management tool for Nix flakes
  fleet.nix._.npins = {
    description = "npins - Pin management tool for Nix flakes";
  }
  // my.nix._.npins;

  # Note: To use npins sources in other modules (e.g., nvf.nix),
  # import them directly: `import ../../npins/default.nix`
  # This returns a set of all pinned sources that can be used to build plugins.
}
