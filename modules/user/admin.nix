{ fleet, ... }:
{
  # Marker + privileges for a user who administers the machines they live on.
  # admin-groups (modules/user/groups.nix) keys root-equivalent groups off
  # this aspect's presence, so include it only on trusted accounts.
  fleet.user._.admin = {
    description = "Administrator account: wheel + networkmanager, and eligible for admin-groups";
    includes = [
      (fleet.user._.groups [
        "wheel"
        "networkmanager"
      ])
    ];
  };
}
