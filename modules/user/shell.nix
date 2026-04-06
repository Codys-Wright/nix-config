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

  # Shells that have a NixOS/darwin programs.<shell> module
  hasOsModule =
    shell:
    builtins.elem shell [
      "fish"
      "zsh"
      "bash"
    ];

  userShell = shell: user: {
    os =
      { pkgs, ... }:
      {
        users.users.${user.userName}.shell = pkgs.${shell};
      }
      // lib.optionalAttrs (hasOsModule shell) {
        programs.${shell}.enable = true;
      };

    homeManager.programs.${shell}.enable = true;
  };
in
{
  fleet.user._.shell.__functor =
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
