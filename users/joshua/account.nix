# Joshua's Unix account settings (password is set via <fleet.user/password>
# in users/joshua/joshua.nix).
{ ... }:
{
  den.aspects.joshua-account = {
    description = "Joshua's Unix account — normal user, restricted groups, bash shell";

    # `user` class → users.users.joshua on every host he lives on.
    user =
      { pkgs, ... }:
      {
        description = "Joshua";
        shell = pkgs.bashInteractive;
      };

    # Restricted child account: host-wide group grants (input/uinput/kvm
    # from niri, sunshine, virtualization, pipewire, …) must not reach it,
    # so the list is forced. This has to be a real nixos definition —
    # den forwards the `user` class as an evaluated value, which drops
    # mkForce priority.
    provides.to-hosts.nixos =
      { lib, ... }:
      {
        users.users.joshua.extraGroups = lib.mkForce [
          "audio"
          "video"
          "input"
          "networkmanager"
        ];
      };
  };
}
