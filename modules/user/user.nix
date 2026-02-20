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
      <den/primary-user>
      FTS.user._.autologin
      (<den/user-shell> "fish")
    ];
  };
}
