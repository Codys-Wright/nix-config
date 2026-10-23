# OpenCode AI terminal assistant aspect
{ fleet, inputs, ... }:
let
  # Soft vars from the private nix-secrets flake (networking topology).
  domain = inputs.nix-secrets.networking.domains.selfhost;
in
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
            export FORGEJO_URL="https://git.${domain}"
            export GITEA_SERVER_URL="$FORGEJO_URL"
            export FORGEJO_TOKEN="$token"
            export GITEA_TOKEN="$token"
            export TEA_TOKEN="$token"
            exec "$@"
          '';
        };

        # codex and claude are the vendors' self-updating installs, not nix
        # packages: T3 Code updates a provider only when it recognises the
        # install (`codex update` needs $CODEX_HOME/packages/standalone,
        # `claude update` needs ~/.local/bin/claude). Activation installs each
        # once if missing; from then on the tools (or T3) keep them current.
        home.activation.agentClis = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          (
          export PATH="$HOME/.local/bin:${
            lib.makeBinPath (
              with pkgs;
              [
                bash
                coreutils
                curl
                findutils
                gawk
                gnugrep
                gnused
                gnutar
                gzip
                procps
              ]
            )
          }"
          if [ ! -e "$HOME/.codex/packages/standalone/current" ]; then
            run curl -fsSL https://chatgpt.com/codex/install.sh -o "$HOME/.codex-install.sh" \
              && CODEX_NON_INTERACTIVE=1 run sh "$HOME/.codex-install.sh" \
              || warnEcho "codex standalone install failed; rerun activation when online"
            rm -f "$HOME/.codex-install.sh"
          fi
          if [ ! -x "$HOME/.local/bin/claude" ]; then
            run curl -fsSL https://claude.ai/install.sh -o "$HOME/.claude-install.sh" \
              && run bash "$HOME/.claude-install.sh" \
              || warnEcho "claude native install failed; rerun activation when online"
            rm -f "$HOME/.claude-install.sh"
          fi
          )
        '';

        # Fleet/agent claude: nix-pinned claude-code wrapped with forgejo-env,
        # installed under a distinct name and config dir so it never collides
        # with the user's native auto-updating `claude` (~/.local/bin/claude,
        # config in ~/.claude). The native installer keeps that path untouched.
        home.file.".local/bin/claude-fleet" = {
          executable = true;
          text = ''
            #!/usr/bin/env bash
            export CLAUDE_CONFIG_DIR="''${CLAUDE_CONFIG_DIR:-$HOME/.config/claude-fleet}"
            if [[ -x "$HOME/.local/bin/forgejo-env" ]]; then
              exec "$HOME/.local/bin/forgejo-env" ${pkgs.claude-code}/bin/claude "$@"
            fi
            exec ${pkgs.claude-code}/bin/claude "$@"
          '';
        };

        home.packages = with pkgs; [
          opencode
          # claude-code intentionally not in PATH: the claude-fleet wrapper
          # above invokes it by absolute store path, so a bare `claude` in the
          # profile stays the user's native auto-updating install.

          # amazon-q-cli
          # aider-chat
          # copilot-cli
          # crush
          # cursor-cli
          # gemini-cli
          # qwen-code
        ];
      };
  };
}
