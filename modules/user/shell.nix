{
  den,
  lib,
  __findFile,
  ...
}:
let
  description = ''
    Sets a user default shell and enables the shell at OS and Home levels.
  '';

  userShell = shell: user: {
    nixos =
      { pkgs, ... }:
      {
        programs.${shell}.enable = true;
        users.users.${user.userName}.shell = pkgs.${shell};
      };

    darwin =
      { pkgs, ... }:
      {
        programs.${shell}.enable = true;
        users.users.${user.userName}.shell = pkgs.${shell};
      };

    homeManager.programs.${shell}.enable = true;
  };
in
{
  # Set default shell for user
  # Usage: (<FTS.user/shell> { default = "fish"; })
  FTS.user._.shell.__functor =
    _self:
    {
      default ? "fish",
      ...
    }:
    let
      availableShells = [
        "fish"
        "zsh"
        "bash"
        "nushell"
      ];

      _ =
        if !(builtins.elem default availableShells) then
          throw "shell: unknown shell '${default}'. Available: ${builtins.concatStringsSep ", " availableShells}"
        else
          null;
    in
    <den.lib.parametric> {
      inherit description;
      includes = [
        ({ user, ... }: userShell default user)
        ({ home, ... }: userShell default home)
      ];
    };
}
