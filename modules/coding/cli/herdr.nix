# herdr - agent multiplexer that lives in your terminal (tmux for AI coding agents)
{
  fleet,
  inputs,
  lib,
  ...
}:
{
  flake-file.inputs.herdr.url = lib.mkDefault "github:ogulcancelik/herdr/v0.7.4";
  flake-file.inputs.herdr.inputs.nixpkgs.follows = "nixpkgs";

  fleet.coding._.cli._.herdr = {
    description = "herdr — agent multiplexer for the terminal (tmux for AI coding agents)";

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default
        ];

        # Agent skill shipped with herdr — pinned to the same tag as the binary
        # so it always describes the installed CLI. ~/.claude/skills is otherwise
        # unmanaged; this only owns the herdr/ subdir.
        home.file.".claude/skills/herdr/SKILL.md".source = "${inputs.herdr}/SKILL.md";
      };
  };
}
