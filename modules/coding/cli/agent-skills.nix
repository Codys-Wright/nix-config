# Agent skills from the shared fleet-skills repo — the same library Paperclip
# and the Hermes agents load — kept live for Claude Code (~/.claude/skills)
# and Codex (~/.codex/skills) without a switch: nix only installs
# `fleet-skills-sync`, which keeps a git checkout of the repo and symlinks each
# of its skills into both dirs. A timer fast-forwards the checkout, so merged
# skills (new ones too) land within 15 minutes; edits in the checkout are
# live at once. The sync never touches a dirty checkout or one off `main`.
{ lib, ... }:
{
  fleet.coding._.cli._.agent-skills = {
    description = "Live shared agent skills (fleet-skills checkout) for Claude Code and Codex";

    homeManager =
      { config, pkgs, ... }:
      let
        sync = pkgs.writeShellApplication {
          name = "fleet-skills-sync";
          runtimeInputs = [
            pkgs.coreutils
            pkgs.git
            pkgs.openssh
          ];
          text = ''
            repo="''${FLEET_SKILLS_DIR:-${config.xdg.dataHome}/fleet-skills}"
            url="git@github.com:FastTrackStudios/fleet-skills.git"

            if [ ! -d "$repo/.git" ]; then
              git clone --quiet "$url" "$repo"
            elif [ "$(git -C "$repo" branch --show-current)" = main ] &&
              [ -z "$(git -C "$repo" status --porcelain)" ]; then
              git -C "$repo" pull --quiet --ff-only ||
                echo "fleet-skills-sync: pull failed; keeping the current checkout" >&2
            else
              echo "fleet-skills-sync: $repo is off main or has local edits; not pulling" >&2
            fi

            for dir in "$HOME/.claude/skills" "$HOME/.codex/skills"; do
              mkdir -p "$dir"
              # Drop links to skills that left the repo.
              for link in "$dir"/*; do
                if [ -L "$link" ] && [ ! -e "$link" ]; then
                  case "$(readlink "$link")" in "$repo/skills/"*) rm "$link" ;; esac
                fi
              done
              for skill in "$repo"/skills/*/; do
                name="$(basename "$skill")"
                dest="$dir/$name"
                # Leave anything we don't own (a hand-made dir, a tool-shipped
                # skill linked by home-manager) alone.
                if [ -e "$dest" ] && ! { [ -L "$dest" ] && [ "$(readlink "$dest")" = "$repo/skills/$name" ]; }; then
                  echo "fleet-skills-sync: $dest exists and isn't ours; skipping" >&2
                  continue
                fi
                ln -sfn "$repo/skills/$name" "$dest"
              done
            done
          '';
        };
      in
      lib.mkMerge [
        {
          home.packages = [ sync ];
          home.activation.fleet-skills-sync = config.lib.dag.entryAfter [ "linkGeneration" ] ''
            run ${lib.getExe sync} || echo "fleet-skills-sync failed; the timer will retry" >&2
          '';
        }
        (lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
          systemd.user.services.fleet-skills-sync = {
            Unit.Description = "Update the fleet-skills checkout and agent skill links";
            Service = {
              Type = "oneshot";
              ExecStart = lib.getExe sync;
            };
          };
          systemd.user.timers.fleet-skills-sync = {
            Unit.Description = "Update fleet-skills every 15 minutes";
            Timer = {
              OnActiveSec = "1min";
              OnUnitActiveSec = "15min";
            };
            Install.WantedBy = [ "timers.target" ];
          };
        })
        (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
          launchd.agents.fleet-skills-sync = {
            enable = true;
            config = {
              ProgramArguments = [ (lib.getExe sync) ];
              StartInterval = 900;
              RunAtLoad = true;
            };
          };
        })
      ];
  };
}
