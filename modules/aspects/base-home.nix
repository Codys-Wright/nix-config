{
  fleet,
  __findFile,
  ...
}:
{
  fleet.base-home = {
    description = "Base home-manager defaults shared by all users";

    includes = [
      <fleet/user-secrets>
    ];
  };
}
