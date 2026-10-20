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
    includes = [ (<fleet.coding.cli/hermes-node> { user = "rat"; }) ];
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
