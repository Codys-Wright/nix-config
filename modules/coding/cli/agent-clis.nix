# Claude Code and Codex for agent accounts, installed the upstream way so
# they update themselves (T3 Code and Paperclip run whatever is current),
# never pinned by nixpkgs.
#
#   (<fleet.coding.cli/agent-clis> { users = [ "agent" ]; })
#
# A oneshot per user runs at boot and daily. It only installs what is
# missing (~/.local/bin/claude, ~/.local/bin/codex), with the official
# installers (claude.ai/install.sh, chatgpt.com/codex/install.sh); after
# that, `claude` and `codex` keep themselves current. Both are static
# builds, so they run as-is on NixOS.
{ lib, ... }:
let
  installers = {
    claude = "https://claude.ai/install.sh";
    codex = "https://chatgpt.com/codex/install.sh";
  };
in
{
  fleet.coding._.cli._.agent-clis.__functor =
    _self:
    { users, ... }:
    {
      name = "agent-clis(${lib.concatStringsSep "," users})";
      description = "Self-updating Claude Code and Codex for ${lib.concatStringsSep ", " users}";
      nixos =
        { pkgs, ... }:
        let
          ensure = pkgs.writeShellApplication {
            name = "agent-clis-ensure";
            runtimeInputs = with pkgs; [
              bash
              coreutils
              curl
              findutils
              gawk
              gnugrep
              gnused
              gnutar
              gzip
              xz
              procps
              util-linux
            ];
            text = ''
              ${lib.concatStrings (
                lib.mapAttrsToList (bin: url: ''
                  if [ ! -x "$HOME/.local/bin/${bin}" ]; then
                    echo "agent-clis: installing ${bin} for $(id -un)"
                    f=$(mktemp)
                    curl -fsSL -o "$f" ${url}
                    bash "$f" </dev/null
                    rm -f "$f"
                  fi
                '') installers
              )}
            '';
          };
        in
        {
          systemd.services = lib.listToAttrs (
            map (u: {
              name = "agent-clis-${u}";
              value = {
                description = "Install Claude Code and Codex for ${u} if missing";
                after = [ "network-online.target" ];
                wants = [ "network-online.target" ];
                serviceConfig = {
                  Type = "oneshot";
                  User = u;
                  ExecStart = lib.getExe ensure;
                };
              };
            }) users
          );
          systemd.timers = lib.listToAttrs (
            map (u: {
              name = "agent-clis-${u}";
              value = {
                wantedBy = [ "timers.target" ];
                timerConfig = {
                  OnBootSec = "5m";
                  OnCalendar = "daily";
                  Persistent = true;
                };
              };
            }) users
          );
        };
    };
}
