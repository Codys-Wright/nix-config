# OpenCode AI terminal assistant aspect
{ fleet, ... }:
{
  fleet.coding._.tools._.opencode = {
    description = "OpenCode AI terminal assistant";

    homeManager =
      {
        pkgs,
        lib,
        config,
        ...
      }:
      {
        home.sessionPath = [ "${config.home.homeDirectory}/.local/bin" ];

        home.file.".local/bin/forgejo-token" = {
          executable = true;
          text = ''
            #!/usr/bin/env bash
            set -euo pipefail
            api_token_file="$HOME/.config/forgejo/token"
            if [[ -s "$api_token_file" ]]; then
              tr -d "\n" < "$api_token_file"
              printf "\n"
              exit 0
            fi

            cred_file="''${GIT_CREDENTIAL_STORE:-$HOME/.git-credentials}"
            [[ -r "$cred_file" ]] || exit 1
            line="$(grep -m1 '^https://.*@git\\.starcommand\\.live' "$cred_file" || true)"
            [[ -n "$line" ]] || exit 1
            token="$(${pkgs.python3}/bin/python3 -c 'from urllib.parse import urlparse, unquote; import sys; u=urlparse(sys.argv[1]); print(unquote(u.password or ""))' "$line")"
            [[ -n "$token" ]] || exit 1
            printf '%s\n' "$token"
          '';
        };

        home.file.".local/bin/forgejo-env" = {
          executable = true;
          text = ''
            #!/usr/bin/env bash
            set -euo pipefail
            token="$($HOME/.local/bin/forgejo-token)"
            export FORGEJO_URL="https://git.starcommand.live"
            export GITEA_SERVER_URL="$FORGEJO_URL"
            export FORGEJO_TOKEN="$token"
            export GITEA_TOKEN="$token"
            export TEA_TOKEN="$token"
            exec "$@"
          '';
        };

        home.file.".local/bin/codex" = {
          executable = true;
          text = ''
            #!/usr/bin/env bash
            if [[ -x "$HOME/.local/bin/forgejo-env" ]]; then
              exec "$HOME/.local/bin/forgejo-env" ${pkgs.codex}/bin/codex "$@"
            fi
            exec ${pkgs.codex}/bin/codex "$@"
          '';
        };

        # Nix-managed claude-code wrapper. Lives at claude-nix so the
        # Anthropic npm installer can keep its own ~/.local/bin/claude symlink
        # for fast version bumps (npm i -g @anthropic-ai/claude-code).
        home.file.".local/bin/claude-nix" = {
          executable = true;
          text = ''
            #!/usr/bin/env bash
            if [[ -x "$HOME/.local/bin/forgejo-env" ]]; then
              exec "$HOME/.local/bin/forgejo-env" ${pkgs.claude-code}/bin/claude "$@"
            fi
            exec ${pkgs.claude-code}/bin/claude "$@"
          '';
        };

        home.packages = with pkgs; [
          opencode
          claude-code

          # amazon-q-cli
          # aider-chat
          codex
          # copilot-cli
          # crush
          # cursor-cli
          # gemini-cli
          # qwen-code
        ];
      };
  };
}
