{
  inputs,
  fleet,
  __findFile,
  ...
}:

{

  den.hosts.aarch64-darwin = {
    voyager = {
      description = "Portable laptop to take into the field";
      users.cody = {
        userName = "CodyWright";
      };
    };
  };

  den.aspects = {
    voyager = {
      includes = [
        <fleet/fonts>
        <fleet/phoenix>
        # starcommand Hermes runs `voyager` profile sessions here over SSH.
        (<fleet.coding.cli/hermes-node> { user = "CodyWright"; })
        # CodyWright's `gh` / git push to FastTrackStudios + Codys-Wright =
        # fts-forge[bot] (key: sops/hosts/voyager.yaml). This is Cody's own
        # login on voyager: `GH_FORGE=0 gh …` for his personal gh.
        (<fleet.coding.cli/gh-forge> {
          user = "CodyWright";
          home = "/Users/codywright";
          sopsFile = "${inputs.nix-secrets}/sops/hosts/voyager.yaml";
        })
      ];
      darwin =
        { pkgs, ... }:
        {
          environment.systemPackages = [
            pkgs.tailwindcss_4
            pkgs.cachix
          ];
          nix.settings = {
            cores = 10;
            max-jobs = 3;
            trusted-users = [
              "root"
              "@admin"
              "CodyWright"
            ];
          };
        };
    };
  };

}
