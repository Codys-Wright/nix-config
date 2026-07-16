# hunk - review-first terminal diff viewer for agentic coders
{
  fleet,
  inputs,
  lib,
  ...
}:
{
  flake-file.inputs.hunk.url = lib.mkDefault "github:modem-dev/hunk/v0.17.1";
  flake-file.inputs.hunk.inputs.nixpkgs.follows = "nixpkgs";

  fleet.coding._.cli._.hunk = {
    description = "hunk — review-first terminal diff viewer for agentic coders";

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          inputs.hunk.packages.${pkgs.stdenv.hostPlatform.system}.default
        ];

        # Agent skill shipped with hunk — pinned to the same tag as the binary
        # so it always describes the installed CLI. ~/.claude/skills is otherwise
        # unmanaged; this only owns the hunk-review/ subdir.
        home.file.".claude/skills/hunk-review/SKILL.md".source =
          "${inputs.hunk}/skills/hunk-review/SKILL.md";
      };
  };
}
