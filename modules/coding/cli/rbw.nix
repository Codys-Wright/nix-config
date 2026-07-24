# rbw — unofficial Bitwarden CLI, pointed at the fleet's self-hosted
# Vaultwarden (vault.starcommand.live). The fleet's runtime-secrets
# store: API keys and service credentials live in Vaultwarden; sops/
# nix-secrets stays the provisioning bootstrap layer. `rbw login` once
# per user (email prompted; agents use hermes@starcommand.live),
# `rbw get <item>` after — scripts and agent helpers read secrets
# without plaintext .env files.
{ fleet, ... }:
{
  fleet.coding._.cli._.rbw = {
    description = "rbw Bitwarden CLI configured for the self-hosted Vaultwarden (vault.starcommand.live)";

    homeManager =
      { pkgs, lib, ... }:
      {
        programs.rbw = {
          enable = true;
          settings = {
            base_url = lib.mkDefault "https://vault.starcommand.live";
            # Interactive users override with their own email via a
            # user aspect; the agent identity is the fleet default.
            email = lib.mkDefault "hermes@starcommand.live";
            lock_timeout = lib.mkDefault 3600;
            pinentry = lib.mkDefault pkgs.pinentry-curses;
          };
        };
      };
  };
}
