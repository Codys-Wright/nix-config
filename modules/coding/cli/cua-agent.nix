# Computer use for the coding agents: CuaDriver's MCP server registered with
# Claude Code, and its agent skill pack (`cua-driver` skill) in the agents'
# skills dirs. The driver itself comes from the hermes-agent flake: on
# THEBATTLESHIP through `hermes-desktop-mcp cuadriver` / `cua-driver`, which
# join cody's live Wayland session (hosts/THEBATTLESHIP/hermes-desktop.nix);
# on the Macs as `cua-driver` on PATH (fleet.coding._.cli._.hermes-node).
#
# Activation, idempotent, and a no-op on a machine without the driver:
#   - `claude mcp add --scope user cua-computer-use …` when Claude Code has no
#     such server yet (~/.claude.json is Claude's own state file, so the entry
#     is added through the CLI, not written by home-manager);
#   - `cua-driver skills install`: fetches the skill pack matching the
#     driver's version and links it into each agent's skills/ dir (Claude
#     Code, Codex, OpenCode). It never overwrites a link a user made. Needs
#     the network; offline, it warns and the next activation retries.
{ ... }:
{
  fleet.coding._.cli._.cua-agent = {
    description = "CuaDriver computer use for the coding agents: Claude Code MCP server + agent skills";

    homeManager =
      { lib, pkgs, ... }:
      {
        home.activation.cuaAgent = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          (
          export PATH="$HOME/.local/bin:/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:$HOME/.nix-profile/bin:/opt/homebrew/bin:${
            lib.makeBinPath (
              with pkgs;
              [
                coreutils
                gnugrep
              ]
            )
          }:$PATH"
          # The MCP command: the session-joining launcher where there is one
          # (THEBATTLESHIP), else the driver's own `mcp` subcommand.
          if command -v hermes-desktop-mcp >/dev/null 2>&1; then
            mcp=(hermes-desktop-mcp cuadriver)
          elif command -v cua-driver >/dev/null 2>&1; then
            mcp=(cua-driver mcp)
          else
            exit 0
          fi
          if command -v claude >/dev/null 2>&1 && ! claude mcp get cua-computer-use >/dev/null 2>&1; then
            run claude mcp add --scope user cua-computer-use -- "''${mcp[@]}" \
              || warnEcho "cua-agent: could not register the cua-computer-use MCP server with Claude Code"
          fi
          if command -v cua-driver >/dev/null 2>&1; then
            run cua-driver skills install >/dev/null \
              || warnEcho "cua-agent: cua-driver skills install failed (offline?); the next activation retries"
          fi
          )
        '';
      };
  };
}
