{
  fleet,
  __findFile,
  ...
}:
{
  fleet.user = {
    description = ''
      User configuration facet.
      Includes all user-related modules by default.
    '';

    includes = [
      <den/primary-user>
      fleet.user._.autologin
      (<den/user-shell> "fish")
    ];
  };
}
