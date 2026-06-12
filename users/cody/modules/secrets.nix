# Cody's personal secrets wiring — declares which sops secrets get
# decrypted into the home environment and how they are consumed.
# Values live encrypted in users/cody/secrets.yaml (edit: just edit-secrets cody)
{ inputs, ... }:
{
  cody.secrets = {
    description = "Cody's sops secrets — Codeberg SSH key, fly.io API token";
    homeManager =
      { config, lib, ... }:
      let
        flyTokenPath = config.sops.secrets."cody/fly/api_token".path;
        codebergTokenPath = config.sops.secrets."cody/codeberg/api_token".path;
        codebergKeyPath = "${config.home.homeDirectory}/.ssh/codeberg_ed25519";
      in
      {
        # Import sops-nix HM module here — fleet.user-secrets only flows into
        # standalone home configs, not host-embedded home-manager.
        imports = [ inputs.sops-nix.homeManagerModules.sops ];

        sops.age.keyFile = lib.mkDefault "${config.home.homeDirectory}/.config/sops/age/keys.txt";
        sops.defaultSopsFile = lib.mkDefault "${inputs.nix-secrets}/sops/users/cody.yaml";
        # store-path sops file (flake input) — not validatable at eval time
        sops.validateSopsFiles = false;

        sops.secrets = {
          # Private key for Codeberg — symlinked into ~/.ssh so ssh picks it up
          "cody/codeberg/ssh_key" = {
            path = codebergKeyPath;
          };
          # fly.io deploy/API token — exported as FLY_API_TOKEN by shells below
          "cody/fly/api_token" = { };
          # Codeberg API token — exported as CODEBERG_TOKEN for tea/fj/berg
          "cody/codeberg/api_token" = { };
        };

        programs.ssh.matchBlocks."codeberg.org" = {
          hostname = "codeberg.org";
          user = "git";
          identityFile = codebergKeyPath;
          identitiesOnly = true;
        };

        # flyctl reads FLY_API_TOKEN; populate it from the decrypted secret
        # at shell startup (sops-nix decrypts at login via systemd user unit).
        programs.nushell.extraEnv = ''
          if ("${flyTokenPath}" | path exists) {
            $env.FLY_API_TOKEN = (open --raw "${flyTokenPath}" | str trim)
          }
          if ("${codebergTokenPath}" | path exists) {
            $env.CODEBERG_TOKEN = (open --raw "${codebergTokenPath}" | str trim)
          }
        '';
        programs.fish.shellInit = ''
          if test -r "${flyTokenPath}"
            set -gx FLY_API_TOKEN (string trim < "${flyTokenPath}")
          end
          if test -r "${codebergTokenPath}"
            set -gx CODEBERG_TOKEN (string trim < "${codebergTokenPath}")
          end
        '';
      };
  };
}
