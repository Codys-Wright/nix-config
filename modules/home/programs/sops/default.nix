# home level sops. see hosts/common/optional/sops.nix for home/user level
{
  inputs,
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.programs.sops;
  sopsFolder = ./../../../../secrets/sops;
  homeDirectory = config.home.homeDirectory;
in
{
  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  options.${namespace}.programs.sops = with types; {
    enable = mkBoolOpt false "Enable sops for home-manager";
  };

  config = mkIf cfg.enable {
    sops = {
      # This is the location of the host specific age-key and will have been extracted to this location via the nixos sops module
      age.keyFile = "${homeDirectory}/.config/sops/age/keys.txt";

      defaultSopsFile = ./../../../../secrets/sops/shared.yaml;
      validateSopsFiles = false;

      secrets = {
        # placeholder for tokens that haven't been set up yet
        # "tokens/foo" = {
        # };
      };
    };
  };
} 