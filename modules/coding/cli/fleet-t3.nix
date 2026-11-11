# fleet-t3: start, read, steer and watch T3 Code threads on other fleet
# machines, from any Claude Code session (packages/fleet-t3).
#
#   - hosts.json lists every den host with a `t3.url` (hosts/<host>/*.nix);
#     `self` is the machine this home is on, reached on its loopback URL.
#   - `fleet-t3 mcp` is registered with Claude Code at user scope, so every
#     Claude session (T3's included) gets the mcp__fleet-t3__* tools.
#     ~/.claude.json is Claude's own state file, so the entry goes in through
#     the CLI (as cua-agent.nix does), and is replaced if its command changed.
#   - Tokens are mutable state in ~/.local/state/fleet-t3/tokens, not sops:
#     `fleet-t3 pair <host>` approves fleet-t3 over SSH with a one-time T3
#     pairing code (no browser), and the daily `fleet-t3 renew` timer replaces
#     each 30-day token before it expires and revokes the old session. A host
#     that is offline is retried on the next run.
#   - The fleet-t3 skill (fleet-skills) says when and how agents use it.
{ config, lib, ... }:
let
  t3Hosts = lib.foldl' (
    acc: hosts:
    acc
    // lib.mapAttrs' (
      name: host:
      lib.nameValuePair (lib.toLower name) (
        {
          inherit (host.t3) url localUrl;
        }
        // lib.optionalAttrs (host.t3.sshUser != null) { ssh = "${host.t3.sshUser}@${lib.toLower name}"; }
      )
    ) (lib.filterAttrs (_: host: host.t3.url != null) hosts)
  ) { } (lib.attrValues config.den.hosts);
in
{
  fleet.coding._.cli._.fleet-t3 = {
    description = "fleet-t3: drive T3 Code threads on other fleet machines (Claude Code MCP server + CLI + token renewal)";

    homeManager =
      {
        config,
        lib,
        pkgs,
        host ? null,
        ...
      }:
      let
        exe = "${config.home.profileDirectory}/bin/fleet-t3";
        renew = "${pkgs.fleet-t3}/bin/fleet-t3 renew";
      in
      lib.mkMerge [
        {
          home.packages = [ pkgs.fleet-t3 ];

          xdg.configFile."fleet-t3/hosts.json".text = builtins.toJSON (
            {
              hosts = t3Hosts;
            }
            // lib.optionalAttrs (host != null) { self = lib.toLower host.name; }
          );

          home.activation.fleetT3Mcp = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
            (
            export PATH="$HOME/.local/bin:/etc/profiles/per-user/$USER/bin:$HOME/.nix-profile/bin:/opt/homebrew/bin:${
              lib.makeBinPath [
                pkgs.coreutils
                pkgs.gnugrep
              ]
            }:$PATH"
            command -v claude >/dev/null 2>&1 || exit 0
            if ! claude mcp get fleet-t3 2>/dev/null | grep -qF '${exe} mcp'; then
              claude mcp remove --scope user fleet-t3 >/dev/null 2>&1 || true
              run claude mcp add --scope user fleet-t3 -- ${exe} mcp \
                || warnEcho "fleet-t3: could not register the fleet-t3 MCP server with Claude Code"
            fi
            )
          '';
        }

        (lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
          systemd.user.services.fleet-t3-renew = {
            Unit.Description = "Renew fleet-t3's T3 MCP tokens before they expire";
            Service = {
              Type = "oneshot";
              ExecStart = renew;
            };
          };
          systemd.user.timers.fleet-t3-renew = {
            Unit.Description = "Renew fleet-t3's T3 MCP tokens daily";
            Timer = {
              OnCalendar = "daily";
              OnStartupSec = "5min";
              RandomizedDelaySec = "1h";
              Persistent = true;
            };
            Install.WantedBy = [ "timers.target" ];
          };
        })

        (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
          launchd.agents.fleet-t3-renew = {
            enable = true;
            config = {
              ProgramArguments = [
                "${pkgs.fleet-t3}/bin/fleet-t3"
                "renew"
              ];
              StartCalendarInterval = [
                {
                  Hour = 4;
                  Minute = 17;
                }
              ];
              RunAtLoad = true;
              StandardOutPath = "${config.home.homeDirectory}/Library/Logs/fleet-t3-renew.log";
              StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/fleet-t3-renew.log";
            };
          };
        })
      ];
  };
}
