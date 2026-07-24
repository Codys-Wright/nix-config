# Hermes Starcommand - hermes-agent package + SSH-tunneled remote Hermes CLI
{
  fleet,
  inputs,
  lib,
  ...
}:
{
  flake-file.inputs.hermes-agent.url = lib.mkDefault "github:NousResearch/hermes-agent/v2026.7.20";
  flake-file.inputs.hermes-agent.inputs.nixpkgs.follows = "nixpkgs";

  fleet.coding._.cli._.hermes-starcommand = {
    description = "Hermes agent package and hermes-starcommand CLI (SSH tunnel to Starcommand Hermes sessions)";

    # NixOS system packages
    nixos =
      { pkgs, ... }:
      let
        hermesStarcommand = pkgs.writeShellApplication {
          name = "hermes-starcommand";
          runtimeInputs = [
            pkgs.bash
            pkgs.coreutils
            pkgs.openssh
            pkgs.python3
          ];
          text = ''
            set -euo pipefail

            profile="hermes"
            session="''${HERMES_SC_SESSION:-}"
            local_port="''${HERMES_SC_PORT:-18642}"
            ssh_host="''${HERMES_SC_SSH_HOST:-starcommand-root}"
            prompt=()

            while [ "$#" -gt 0 ]; do
              case "$1" in
                -p|--profile)
                  profile="$2"
                  shift 2
                  ;;
                -s|--session)
                  session="$2"
                  shift 2
                  ;;
                --port)
                  local_port="$2"
                  shift 2
                  ;;
                --ssh-host)
                  ssh_host="$2"
                  shift 2
                  ;;
                -h|--help)
                  cat <<'EOF'
            Usage: hermes-starcommand [--session NAME] [--profile hermes|researcher|jarvis|curator] [PROMPT...]

            Without PROMPT, starts a simple terminal REPL.
            Each --session value maps to a separate Starcommand Hermes session.
            EOF
                  exit 0
                  ;;
                --)
                  shift
                  prompt+=("$@")
                  break
                  ;;
                *)
                  prompt+=("$1")
                  shift
                  ;;
              esac
            done

            case "$profile" in
              hermes) remote_port=8642 ;;
              researcher) remote_port=8643 ;;
              jarvis) remote_port=8644 ;;
              curator) remote_port=8645 ;;
              *)
                echo "unknown profile: $profile" >&2
                exit 2
                ;;
            esac

            if [ -z "$session" ]; then
              cwd_name="$(basename "$PWD")"
              session="''${cwd_name:-terminal}"
            fi

            if ! timeout 1 bash -c ":</dev/tcp/127.0.0.1/$local_port" 2>/dev/null; then
              ssh -fNT \
                -o ExitOnForwardFailure=yes \
                -o ServerAliveInterval=30 \
                -o ServerAliveCountMax=2 \
                -L "127.0.0.1:$local_port:127.0.0.1:$remote_port" \
                "$ssh_host"
            fi

            export HERMES_SC_URL="http://127.0.0.1:$local_port/v1/chat/completions"
            export HERMES_SC_PROFILE="$profile"
            export HERMES_SC_SESSION_ID="$session"
            export HERMES_STARCOMMAND_API_KEY="''${HERMES_STARCOMMAND_API_KEY:-28f0ffa83dc851454bcc7c33891c77eb212c2dab1a60c0314a8a0375132fd57c}"

            if [ "''${#prompt[@]}" -gt 0 ]; then
              HERMES_SC_PROMPT="''${prompt[*]}" python3 - <<'PY'
            import json
            import os
            import sys
            import urllib.request

            prompt = os.environ["HERMES_SC_PROMPT"]
            url = os.environ["HERMES_SC_URL"]
            session = os.environ["HERMES_SC_SESSION_ID"]
            profile = os.environ["HERMES_SC_PROFILE"]
            key = os.environ.get("HERMES_STARCOMMAND_API_KEY", "")

            body = {
                "model": profile,
                "messages": [{"role": "user", "content": prompt}],
                "stream": False,
            }
            headers = {
                "Content-Type": "application/json",
                "X-Hermes-Session-Id": session,
                "X-Hermes-Session-Key": session,
            }
            if key:
                headers["Authorization"] = f"Bearer {key}"
            req = urllib.request.Request(url, data=json.dumps(body).encode(), headers=headers)
            try:
                with urllib.request.urlopen(req, timeout=3600) as resp:
                    data = json.loads(resp.read().decode())
            except Exception as exc:
                print(f"hermes-starcommand: request failed: {exc}", file=sys.stderr)
                raise SystemExit(1)
            print(data.get("choices", [{}])[0].get("message", {}).get("content", ""))
            PY
              exit 0
            fi

            echo "Hermes Starcommand [$profile/$session]. Ctrl-D to exit."
            while true; do
              printf '> '
              if ! IFS= read -r line; then
                echo
                break
              fi
              [ -n "$line" ] || continue
              HERMES_SC_PROMPT="$line" python3 - <<'PY'
            import json
            import os
            import sys
            import urllib.request

            prompt = os.environ["HERMES_SC_PROMPT"]
            url = os.environ["HERMES_SC_URL"]
            session = os.environ["HERMES_SC_SESSION_ID"]
            profile = os.environ["HERMES_SC_PROFILE"]
            key = os.environ.get("HERMES_STARCOMMAND_API_KEY", "")

            body = {
                "model": profile,
                "messages": [{"role": "user", "content": prompt}],
                "stream": False,
            }
            headers = {
                "Content-Type": "application/json",
                "X-Hermes-Session-Id": session,
                "X-Hermes-Session-Key": session,
            }
            if key:
                headers["Authorization"] = f"Bearer {key}"
            req = urllib.request.Request(url, data=json.dumps(body).encode(), headers=headers)
            try:
                with urllib.request.urlopen(req, timeout=3600) as resp:
                    data = json.loads(resp.read().decode())
            except Exception as exc:
                print(f"hermes-starcommand: request failed: {exc}", file=sys.stderr)
                raise SystemExit(1)
            print(data.get("choices", [{}])[0].get("message", {}).get("content", ""))
            PY
            done
          '';
        };
      in
      {
        environment.systemPackages = [
          inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default
          hermesStarcommand
        ];
      };

    # Darwin system packages
    darwin =
      { pkgs, ... }:
      {
        environment.systemPackages = [
          inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default
        ];
      };
  };
}
