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
    if shell == "nushell" then
      # nushell is the *interactive* shell only. The account's login shell
      # stays bash, because everything that runs commands through the login
      # shell — coding agents (Claude Code, Codex, T3), `ssh host 'cmd'`,
      # editors, scripts — expects POSIX syntax. Bash execs nu only for a
      # human at a terminal: interactive, on a TTY, not already started from
      # nu (so `bash` typed inside nu stays bash). Set NO_NU=1 to stay in bash.
      {
        name = "user-shell(nushell)";
        description = "Login shell bash for tools and agents; terminals open nushell";

        user = { pkgs, ... }: { shell = pkgs.bash; };
        homeManager =
          { pkgs, ... }:
          {
            programs.nushell.enable = true;
            programs.bash = {
              enable = true;
              initExtra = lib.mkAfter ''
                if [[ $- == *i* && -t 0 && -t 1 && -z ''${NO_NU:-} ]] \
                  && [[ "$(cat /proc/$PPID/comm 2>/dev/null)" != nu ]]; then
                  exec ${lib.getExe pkgs.nushell}
                fi
              '';
            };
          };
      }
    else
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
