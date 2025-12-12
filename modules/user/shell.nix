{
  lib,
  ...
}:
{
  # Set default shell for user
  # Usage: (FTS.user._.shell { default = "fish"; })
  FTS.user._.shell.__functor =
    _self:
    {
      default ? "fish",
      ...
    }@args:
    { user, ... }:
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
    {
      nixos =
        { pkgs, ... }:
        {
          # Enable the shell system-wide
          programs.${default}.enable = true;
          # Set as the user's default shell
          users.users.${user.userName}.shell = pkgs.${default};
        };
      darwin =
        { pkgs, ... }:
        {
          # Enable the shell on Darwin
          programs.${default}.enable = true;
          # Set as the user's default shell
          users.users.${user.userName}.shell = pkgs.${default};
        };
    };
}

