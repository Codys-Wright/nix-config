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
      (<fleet.coding.cli/gh-forge> {
        user = "rat";
        home = "/Users/rat";
        sopsFile = "${inputs.nix-secrets}/sops/hosts/airlock.yaml";
      })
      # Claude Code + Codex go through the fleet proxy on starcommand (LAN).
      (<fleet.coding.cli/cliproxyapi-client> {
        baseUrl = "http://192.168.1.112:8317";
        sopsFile = "${inputs.nix-secrets}/sops/hosts/airlock.yaml";
        users.rat = "agents";
      })
    ];
    darwin =
      { config, pkgs, ... }:
      {
        nix.enable = lib.mkForce false;
        nix.optimise.automatic = lib.mkForce false;

        # Determinate Nix owns /etc/nix/nix.conf and includes nix.custom.conf,
        # so the fleet caches go there instead of nix.settings (inert while
        # nix.enable is false). Listing them as system substituters lets the
        # GitHub runners (rat) use them without making rat a trusted user.
        environment.etc."nix/nix.custom.conf" = {
          # What the Determinate installer wrote, so the first switch can replace it.
          knownSha256Hashes = [ "3bd68ef979a42070a44f8d82c205cfd8e8cca425d91253ec2c10a88179bb34aa" ];
          text =
            let
              inherit (config.nix.settings) substituters trusted-public-keys;
            in
            ''
              # Managed by nix-fleet (hosts/airlock/airlock.nix).
              extra-substituters = ${toString substituters}
              extra-trusted-substituters = ${toString substituters}
              extra-trusted-public-keys = ${toString trusted-public-keys}
            '';
        };

        # The hand-placed proxy + gh-forge config this replaces on the first switch.
        environment.etc."codex/config.toml".knownSha256Hashes = [
          "dce24dfcc4ef46f8a6e73bc702d4fb7af5c704f45365ceaa7090a9b528038c0a"
        ];

        # Authorize cody's key on the build user so remote iOS builds
        # (dx / xcodebuild driven over SSH) can reach airlock.
        users.users.rat.openssh.authorizedKeys.keys = [
          ssh-keys.personal.cody
        ];
      };
  };

}
