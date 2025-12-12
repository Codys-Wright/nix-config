{
  FTS,
  ...
}:
{
  FTS.user = {
    description = ''
      User configuration facet.
      Includes all user-related modules by default.
    '';

    includes = [
      FTS.user._.admin
      FTS.user._.autologin
      FTS.user._.shell
    ];
  };
}

