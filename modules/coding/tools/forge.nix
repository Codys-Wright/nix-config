# Forge CLIs - work with Codeberg / Forgejo / Gitea from the terminal
{ fleet, ... }:
{
  fleet.coding._.tools._.forge = {
    description = "Forge CLIs — tea (Gitea/Forgejo), fj (forgejo-cli), berg (codeberg-cli)";

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.tea # official Gitea CLI, works with Forgejo/Codeberg
          pkgs.forgejo-cli # `fj` — Forgejo-native CLI
          pkgs.codeberg-cli # `berg` — Codeberg-specific CLI
        ];
      };
  };
}
