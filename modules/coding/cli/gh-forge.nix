# gh-forge for an agent account: `gh` (and git over https to github.com) acts
# as the FTS - Forge GitHub App, fts-forge[bot] (Captain, 2026-10-21), so
# Hermes workers on this host push their branches and open their own PRs.
#
#   (<fleet.coding.cli/gh-forge> { user = "agent"; home = "/home/agent"; sopsFile = …; })
#
# - pkgs.gh-forge, hiPrio over pkgs.gh: `gh` = gh-forge, which mints a short-
#   lived installation token per call (owner from -R / the remote) and execs
#   the real gh. `GH_FORGE=0 gh …` runs plain gh.
# - The App key comes from sops (key `github_app_fts_forge_private_key` in the
#   host file) to /run/secrets/github-apps/fts-forge.pem, owned by `user`,
#   0400. It never enters the store. Keeper inventories the name.
# - git: activation appends, for https://github.com/{FastTrackStudios,
#   Codys-Wright}, an empty helper (resets whatever came before) plus the
#   App's credential helper to ~/.gitconfig, idempotently. Other owners keep
#   the account's own credentials.
#
# NixOS: the host must already import sops-nix (THEBATTLESHIP-sops does).
# nix-darwin: this imports sops-nix's darwin module and decrypts with the
# host SSH key.
{ inputs, ... }:
let
  owners = [
    "FastTrackStudios"
    "Codys-Wright"
  ];
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
in
{
  fleet.coding._.cli._.gh-forge.__functor =
    _self:
    {
      user,
      home,
      sopsFile,
      keySopsKey ? "github_app_fts_forge_private_key",
      ...
    }:
    let
      # Default path /run/secrets/github-apps/fts-forge.pem — what pkgs.gh-forge
      # reads ($GITHUB_APP_KEY_FILE). One agent account per host.
      secretName = "github-apps/fts-forge.pem";
      secret = {
        inherit sopsFile;
        key = keySopsKey;
        owner = user;
        mode = "0400";
      };
    in
    {
      name = "gh-forge(${user})";
      description = "gh and git push as the FTS - Forge GitHub App for ${user}";
      nixos =
        { lib, pkgs, ... }:
        {
          users.users.${user}.packages = [ (lib.hiPrio pkgs.gh-forge) ];
          sops.secrets.${secretName} = secret // {
            group = "users";
          };
          system.activationScripts."gh-forge-git-${user}" = {
            deps = [ "users" ];
            text = gitScript {
              inherit (pkgs) git;
              inherit user home;
              tokenBin = "/etc/profiles/per-user/${user}/bin/github-app-token";
            };
          };
        };
      darwin =
        { lib, pkgs, ... }:
        {
          imports = [ inputs.sops-nix.darwinModules.sops ];
          environment.systemPackages = [ (lib.hiPrio pkgs.gh-forge) ];
          sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
          sops.secrets.${secretName} = secret // {
            group = "staff";
          };
          system.activationScripts.postActivation.text = lib.mkAfter (gitScript {
            inherit (pkgs) git;
            inherit user home;
            tokenBin = "/run/current-system/sw/bin/github-app-token";
          });
        };
    };
}
