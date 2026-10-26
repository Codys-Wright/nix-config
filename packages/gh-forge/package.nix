# gh-forge: gh (and git over https) as the FTS - Forge GitHub App
# (fts-forge[bot]). Same scripts as starcommand's Hermes image
# (modules/flake/hermes-tools/); keep the two copies in step.
#
#   bin/github-app-token  mint an installation token / git credential helper
#   bin/gh-forge          the real gh with GH_TOKEN = a fresh bot token
#   bin/gh                exec gh-forge (install with lib.hiPrio to shadow pkgs.gh)
#
# `defaultOn = false` builds the variant for a human account: plain gh unless
# GH_FORGE=1, which the agent tools (Claude Code, Codex, Paperclip) set.
#
# The App key is never in the store: the token tool reads
# $GITHUB_APP_KEY_FILE (default /run/secrets/github-apps/<app>.pem, which
# sops-nix decrypts owned by the agent user, 0400) or the usual
# ~/.config/github-apps/<app>/. appId is public and baked in as $GITHUB_APP_ID's default.
{
  lib,
  runCommand,
  writers,
  python3Packages,
  gh,
  appId ? "5391924",
  keyFile ? "/run/secrets/github-apps/{app}.pem",
  defaultOn ? true,
}:
let
  githubAppToken = writers.writePython3Bin "github-app-token" {
    libraries = [
      python3Packages.pyjwt
      python3Packages.cryptography
    ];
    flakeIgnore = [
      "E501"
      "E741"
    ];
  } (builtins.readFile ./github-app-token.py);
in
runCommand "gh-forge"
  {
    meta = {
      description = "gh and git credentials as the FTS - Forge GitHub App";
      mainProgram = "gh";
    };
  }
  ''
    mkdir -p $out/bin
    cat > $out/bin/github-app-token <<EOF
    #!/bin/sh
    : "\''${GITHUB_APP_ID:=${appId}}"
    # Not \''${VAR:=…}: the "}" in "{app}" would end the expansion early
    # (default became ".../{app"), so the sops key was never found.
    [ -n "\''${GITHUB_APP_KEY_FILE:-}" ] || GITHUB_APP_KEY_FILE='${keyFile}'
    export GITHUB_APP_ID GITHUB_APP_KEY_FILE
    exec ${githubAppToken}/bin/github-app-token "\$@"
    EOF
    substitute ${./gh-forge.sh} $out/bin/gh-forge \
      --replace-fail @GH@ ${gh}/bin/gh \
      --replace-fail @TOKEN@ $out/bin/github-app-token \
      --replace-fail @DEFAULT@ ${if defaultOn then "1" else "0"}
    printf '#!/bin/sh\nexec %s "$@"\n' $out/bin/gh-forge > $out/bin/gh
    chmod +x $out/bin/*
  ''
