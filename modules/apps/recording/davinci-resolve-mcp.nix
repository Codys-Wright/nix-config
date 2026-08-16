# MCP server for DaVinci Resolve — lets an MCP client (Claude Code) drive
# Resolve's scripting API: media pool organisation, timeline edits, colour,
# Fusion, Fairlight and render jobs.
#
# `studio` must match the edition the host installs via
# <fleet.apps/davinci-resolve>, since the wrapper bakes in that build's
# scripting-library path.
# Usage: (fleet.apps._.davinci-resolve-mcp { studio = true; })
#
# Resolve itself must be running, with Preferences > System > General >
# "External scripting using" set to Local (Studio only; the free edition falls
# back to the in-app Workspace > Scripts bridge).
{
  fleet,
  ...
}:
{
  fleet.apps._.davinci-resolve-mcp.description =
    "MCP server exposing DaVinci Resolve's scripting API";

  fleet.apps._.davinci-resolve-mcp.__functor =
    _self:
    {
      studio ? false,
      ...
    }:
    {
      nixos =
        { pkgs, ... }:
        {
          environment.systemPackages = [
            (pkgs.davinci-resolve-mcp.override {
              studioVariant = studio;
            })
          ];
        };
    };
}
