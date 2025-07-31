{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.config.nix;
  user = config.${namespace}.config.user;
in
{
  options.${namespace}.config.nix = {
    enable = mkBoolOpt false "${namespace}.config.nix.enable";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      nix-health
      nix-index
      nix-output-monitor
      nix-prefetch-git
      nixfmt-rfc-style
    ];
    nix =
      let
        users = [
          "root"
          user.name
        ];
      in
      {
        package = pkgs.nixVersions.latest;
        gc = {
          options = "--delete-older-than 30d";
          dates = "daily";
          automatic = true;
        };

        settings = {
          trusted-users = users;
          sandbox = "relaxed";
          auto-optimise-store = true;
          allowed-users = users;
          experimental-features = "nix-command flakes";
          http-connections = 50;
          warn-dirty = false;
          log-lines = 50;
        };
        # flake-utils-plus
        generateRegistryFromInputs = true;
        generateNixPathFromInputs = true;
        linkInputs = true;
      };
  };
}
