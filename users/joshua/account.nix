# Joshua's Unix account settings (password is set via <fleet.user/password>
# in users/joshua/joshua.nix).
{ ... }:
{
  den.aspects.joshua-account = {
    description = "Joshua's Unix account — normal user, restricted groups, bash shell";

    nixos =
      { lib, pkgs, ... }:
      {
        users.users.joshua = {
          isNormalUser = true;
          description = "Joshua";
          shell = pkgs.bashInteractive;
          extraGroups = lib.mkForce [
            "audio"
            "video"
            "input"
            "networkmanager"
          ];
        };
      };
  };
}
