# gh-forge: `gh` (and git over https to github.com) acts as the FTS - Forge
# GitHub App, fts-forge[bot] (Captain, 2026-10-21), so agents push their own
# branches and open their own PRs, and anything the Captain did himself
# stays under his name.
#
#   (<fleet.coding.cli/gh-forge> {
#     user = "agent"; home = "/home/agent";   # an account that is always the bot
#     humans = [ "cody" ];                    # accounts that are the bot only inside agent tools
#     sopsFile = …;
#   })
#
# - `user` (optional): pkgs.gh-forge, hiPrio over pkgs.gh, so `gh` mints a
#   short-lived installation token per call (owner from -R / the remote) and
#   execs the real gh. Activation also points ~/.gitconfig's github.com
#   credentials for the bot's owners at the App. `GH_FORGE=0 gh …` runs plain gh.
# - `humans`: the same `gh`, built to stay plain gh unless GH_FORGE=1. No
#   ~/.gitconfig changes; their own credentials and SSH remotes stay theirs.
# - Agent tools: Claude Code (a managed-settings drop-in) and Codex (the
#   system config's shell environment) set GH_FORGE=1, the bot's commit
#   identity, and git config through GIT_CONFIG_* that sends the bot's owners
#   over https with the App's credential helper. That rewrite is more specific
#   than a personal `url.git@github.com:.insteadOf https://github.com/`, so it
#   wins inside agent tools only. Paperclip SSH environments set the same env.
# - The App key comes from sops (key `github_app_fts_forge_private_key` in the
#   host file) to /run/secrets/github-apps/fts-forge.pem, 0440, readable by
#   `user` and `humans`. It never enters the store. Keeper inventories the name.
#
# NixOS: the host must already import sops-nix (THEBATTLESHIP-sops does).
# nix-darwin: this imports sops-nix's darwin module and decrypts with the
# host SSH key.
{ inputs, lib, ... }:
let
  owners = [
    "FastTrackStudios"
    "Codys-Wright"
  ];
  # fts-forge[bot]'s GitHub user id (gh api '/users/fts-forge[bot]').
  botName = "fts-forge[bot]";
  botEmail = "345159799+fts-forge[bot]@users.noreply.github.com";

  gitScript =
    {
      git,
      user,
      home,
      tokenBin,
    }:
    ''
      f=${home}/.gitconfig
      g="${git}/bin/git config --file $f"
      $g credential.https://github.com.useHttpPath true
      ${builtins.concatStringsSep "\n" (
        map (o: ''
          $g --unset-all credential.https://github.com/${o}.helper || true
          $g --add credential.https://github.com/${o}.helper ""
          $g --add credential.https://github.com/${o}.helper '!${tokenBin} --git-credential fts-forge --owner ${o}'
        '') owners
      )}
      chown ${user} "$f"
    '';

  # Environment for every process an agent tool starts.
  agentEnv =
    tokenBin:
    let
      gitConfig = [
        {
          key = "credential.https://github.com.useHttpPath";
          value = "true";
        }
      ]
      ++ lib.concatMap (o: [
        {
          key = "url.https://github.com/${o}/.insteadOf";
          value = "https://github.com/${o}/";
        }
        {
          key = "url.https://github.com/${o}/.insteadOf";
          value = "git@github.com:${o}/";
        }
        {
          key = "url.https://github.com/${o}/.insteadOf";
          value = "ssh://git@github.com/${o}/";
        }
        {
          key = "credential.https://github.com/${o}.helper";
          value = "";
        }
        {
          key = "credential.https://github.com/${o}.helper";
          value = "!${tokenBin} --git-credential fts-forge --owner ${o}";
        }
      ]) owners;
    in
    {
      GH_FORGE = "1";
      GIT_AUTHOR_NAME = botName;
      GIT_AUTHOR_EMAIL = botEmail;
      GIT_COMMITTER_NAME = botName;
      GIT_COMMITTER_EMAIL = botEmail;
      GIT_CONFIG_COUNT = toString (builtins.length gitConfig);
    }
    // lib.listToAttrs (
      lib.concatLists (
        lib.imap0 (i: c: [
          (lib.nameValuePair "GIT_CONFIG_KEY_${toString i}" c.key)
          (lib.nameValuePair "GIT_CONFIG_VALUE_${toString i}" c.value)
        ]) gitConfig
      )
    );

  codexEnv = env: ''

    # Managed by the fleet (gh-forge): commands Codex runs act as fts-forge[bot].
    [shell_environment_policy.set]
    ${lib.concatStrings (lib.mapAttrsToList (k: v: "${k} = ${builtins.toJSON v}\n") env)}'';
in
{
  fleet.coding._.cli._.gh-forge.__functor =
    _self:
    {
      user ? null,
      home ? null,
      humans ? [ ],
      sopsFile,
      keySopsKey ? "github_app_fts_forge_private_key",
      ...
    }:
    let
      # Default path /run/secrets/github-apps/fts-forge.pem — what pkgs.gh-forge
      # reads ($GITHUB_APP_KEY_FILE). One copy per host, shared by group.
      secretName = "github-apps/fts-forge.pem";
      readers = lib.optional (user != null) user ++ humans;
      secret = {
        inherit sopsFile;
        key = keySopsKey;
        owner = builtins.head readers;
        mode = "0440";
      };
      humanGh = pkgs: pkgs.gh-forge.override { defaultOn = false; };
    in
    assert readers != [ ];
    {
      name = "gh-forge(${lib.concatStringsSep "," readers})";
      description = "gh and git push as the FTS - Forge GitHub App for ${lib.concatStringsSep ", " readers}";
      nixos =
        { pkgs, ... }:
        let
          tokenBin = "${pkgs.gh-forge}/bin/github-app-token";
        in
        lib.mkMerge [
          {
            users.groups.fts-forge.members = readers;
            sops.secrets.${secretName} = secret // {
              group = "fts-forge";
            };
            environment.etc."claude-code/managed-settings.d/60-gh-forge.json".text = builtins.toJSON {
              env = agentEnv tokenBin;
            };
            environment.etc."codex/config.toml".text = lib.mkAfter (codexEnv (agentEnv tokenBin));
          }
          (lib.mkIf (user != null) {
            users.users.${user}.packages = [ (lib.hiPrio pkgs.gh-forge) ];
            system.activationScripts."gh-forge-git-${user}" = {
              deps = [ "users" ];
              text = gitScript {
                inherit (pkgs) git;
                inherit user home tokenBin;
              };
            };
          })
          {
            users.users = lib.genAttrs humans (_: {
              packages = [ (lib.hiPrio (humanGh pkgs)) ];
            });
          }
          # Home-manager's profile comes first on PATH and carries plain gh
          # (nvf), so the human build has to win there too. Hosts without
          # humans may not have home-manager at all.
          (lib.optionalAttrs (humans != [ ]) {
            home-manager.users = lib.genAttrs humans (_: {
              home.packages = [ (lib.hiPrio (humanGh pkgs)) ];
            });
          })
        ];
      darwin =
        { pkgs, ... }:
        let
          tokenBin = "${pkgs.gh-forge}/bin/github-app-token";
          dropIn = pkgs.writeText "60-gh-forge.json" (builtins.toJSON { env = agentEnv tokenBin; });
          dir = "/Library/Application Support/ClaudeCode/managed-settings.d";
        in
        lib.recursiveUpdate
          (lib.optionalAttrs (humans != [ ]) {
            home-manager.users = lib.genAttrs humans (_: {
              home.packages = [ (lib.hiPrio (humanGh pkgs)) ];
            });
          })
          {
            imports = [ inputs.sops-nix.darwinModules.sops ];
            # System-wide on darwin: the always-bot build when there is an agent
            # account, else the human build.
            environment.systemPackages = [
              (lib.hiPrio (if user != null then pkgs.gh-forge else humanGh pkgs))
            ];
            sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
            # Every macOS login account is in staff.
            sops.secrets.${secretName} = secret // {
              group = "staff";
            };
            environment.etc."codex/config.toml".text = lib.mkAfter (codexEnv (agentEnv tokenBin));
            system.activationScripts.postActivation.text = lib.mkAfter (
              ''
                mkdir -p "${dir}"
                ln -sfn ${dropIn} "${dir}/60-gh-forge.json"
              ''
              + lib.optionalString (user != null) (gitScript {
                inherit (pkgs) git;
                inherit user home tokenBin;
              })
            );
          };
    };
}
