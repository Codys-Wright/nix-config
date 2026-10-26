{
  inputs,
  fleet,
  ssh-keys,
  lib,
  __findFile,
  ...
}:

{

  den.hosts.aarch64-darwin = {
    airlock = {
      description = "An Mac Mini that holds all the proprietary garbage that can't run on linux";
      deployment = {
        ip = "192.168.1.116"; # DHCP — reserve it on the router
        sshPort = 22;
        sshUser = "rat";
      };
    };
  };

  den.aspects.airlock = {
    # starcommand Hermes runs `airlock` profile sessions here over SSH.
    includes = [
      (<fleet.coding.cli/hermes-node> { user = "rat"; })
      # rat's `gh` / git push = fts-forge[bot] (key: sops/hosts/airlock.yaml).
      # Claude Code + Codex go through the fleet proxy on starcommand (LAN).
      # rat is the agent account, so everything here bills to the agents key.
      (<fleet.coding.cli/cliproxyapi-client> {
        baseUrl = "http://192.168.1.112:8317";
        sopsFile = "${inputs.nix-secrets}/sops/hosts/airlock.yaml";
        users.rat = "agents";
      })
      (<fleet.coding.cli/gh-forge> {
        user = "rat";
        home = "/Users/rat";
        sopsFile = "${inputs.nix-secrets}/sops/hosts/airlock.yaml";
      })
    ];
    darwin =
      { pkgs, ... }:
      {
        nix.enable = lib.mkForce false;
        nix.optimise.automatic = lib.mkForce false;

        # Authorize cody's key on the build user so remote iOS builds
        # (dx / xcodebuild driven over SSH) can reach airlock.
        users.users.rat.openssh.authorizedKeys.keys = [
          ssh-keys.personal.cody
        ];
      };
  };

}
