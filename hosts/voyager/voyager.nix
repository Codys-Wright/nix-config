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
        # Cody's own login: his `gh` / git push stay his, except inside
        # Claude Code / Codex / Paperclip, which act as fts-forge[bot]
        # (key: sops/hosts/voyager.yaml).
        # Claude Code + Codex go through the fleet proxy on starcommand, by its
        # public name: this is the laptop, so it has to work away from home.
        # Cody's own sessions use his key; Paperclip runs override it with the agents key.
        (<fleet.coding.cli/cliproxyapi-client> {
          baseUrl = "https://ai-proxy.starcommand.live";
          sopsFile = "${inputs.nix-secrets}/sops/hosts/voyager.yaml";
          users.CodyWright = "cody";
        })
        (<fleet.coding.cli/gh-forge> {
          humans = [ "CodyWright" ];
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
