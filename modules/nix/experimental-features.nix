# Nix experimental features configuration
{
  FTS,
  ...
}:
{
  FTS.experimental-features = {
    description = "Enable Nix experimental features (nix-command and flakes)";

    nixos = { config, lib, ... }: {
      nix.settings.experimental-features = [ "nix-command" "flakes" ];
    };
  };
}

