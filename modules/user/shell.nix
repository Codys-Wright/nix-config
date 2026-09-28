# A user's login shell, enabled at OS and home level.
#
#   den.aspects.vic.includes = [ (<fleet.user/shell> "nushell") ];
#
# Like den's <den/user-shell>, but also accepts nushell, which has no
# NixOS/nix-darwin `programs.<shell>` module.
{ lib, ... }:
let
  availableShells = [
    "fish"
    "zsh"
    "bash"
    "nushell"
  ];
  # Shells that have a NixOS/darwin programs.<shell> module
  hasOsModule =
    shell:
    builtins.elem shell [
      "fish"
      "zsh"
      "bash"
    ];
in
{
  fleet.user._.shell.__functor =
    _self: shell:
    assert lib.assertMsg (builtins.elem shell availableShells)
      "shell: unknown shell '${shell}'. Available: ${lib.concatStringsSep ", " availableShells}";
    {
      name = "user-shell(${shell})";
      description = "Sets the user's login shell to ${shell}";

      user = { pkgs, ... }: { shell = pkgs.${shell}; };
      provides.to-hosts.os = lib.optionalAttrs (hasOsModule shell) {
        programs.${shell}.enable = true;
      };
      homeManager.programs.${shell}.enable = true;
    };
}
