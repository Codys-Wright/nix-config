{
  FTS,
  __findFile,
  ...
}:
{
  FTS.base-home = {
    description = "Base home-manager defaults shared by all users";

    includes = [
      <FTS/user-secrets>
    ];
  };
}
