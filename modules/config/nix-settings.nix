{
  FTS,
  pkgs,
  ...
}:
let
  nixSettings =
    { config, ... }:
    {
      nix = {
        optimise.automatic = true;
        settings = {
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          trusted-users = [
            "root"
            "@wheel"
          ];
          substituters = [
            "https://cache.nixos.org/"
          ];
        };
        gc = pkgs.lib.optionalAttrs config.nix.enable {
          automatic = true;
          options = "--delete-older-than 7d";
        };
      };
    };
in
{
  FTS.nix-settings = {
    description = "Shared nix settings for NixOS and nix-darwin";
    nixos = nixSettings;
    darwin = nixSettings;
  };
}
