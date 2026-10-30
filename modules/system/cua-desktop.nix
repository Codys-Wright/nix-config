# Computer use on a user's niri desktop: the `cua-driver` CLI (joins that
# user's live session) and its daemon, up with their graphical session.
#
#   (<fleet.system/cua-desktop> { user = "carter"; })
#
# Driving it over SSH: `ssh <user>@<host> cua-driver call get_screen_size`
# (or as root: `runuser -u <user> -- cua-driver call …`).
{ fleet, inputs, ... }:
{
  fleet.system._.cua-desktop = {
    description = "CuaDriver computer use on one user's niri desktop (CLI + session daemon)";

    __functor =
      _self:
      { user }:
      {
        nixos =
          { pkgs, ... }:
          let
            cua = import ./_cua-driver.nix { inherit inputs pkgs; };
          in
          {
            environment.systemPackages = [ cua.cli ];

            # The daemon `cua-driver call …` talks to (~/.cache/cua-driver/
            # cua-driver.sock), up for the user's graphical session; MCP
            # routes (`cua-driver mcp`) run their own and don't need it.
            systemd.user.services.cua-driver = {
              description = "CuaDriver daemon (computer use) for ${user}'s desktop session";
              wantedBy = [ "graphical-session.target" ];
              partOf = [ "graphical-session.target" ];
              after = [ "graphical-session.target" ];
              unitConfig.ConditionUser = user;
              serviceConfig = {
                ExecStart = "${cua.cli}/bin/cua-driver serve";
                Restart = "on-failure";
                RestartSec = 5;
              };
            };
          };
      };
  };
}
