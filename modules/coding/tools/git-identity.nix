# Git identity — set user name and email for commits
#
# Usage:
#   (fleet.git-identity { name = "Carter"; email = "carter@example.com"; })
{
  fleet,
  ...
}:
{
  fleet.git-identity = {
    description = "Set git user name and email for commits";

    __functor =
      _self:
      {
        name,
        email,
      }:
      { class, aspect-chain }:
      {
        homeManager =
          { lib, ... }:
          {
            programs.git.settings.user.name = lib.mkForce name;
            programs.git.settings.user.email = lib.mkForce email;
          };
      };
  };
}
