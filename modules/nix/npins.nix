# npins — pin management for sources outside the flake inputs.
# Pins live in npins/sources.json (currently only nvzone-floaterm, read by
# modules/coding/editor/nvf.nix via `import ../../../npins/default.nix`).
{
  fleet.nix._.npins = {
    description = "npins - Pin management tool for Nix flakes";

    os =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.npins ];
      };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.npins ];
      };
  };
}
