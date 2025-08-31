# hosts level sops. see home/[user]/common/optional/sops.nix for home/user level
{
  pkgs,
  lib,
  inputs,
  config,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.programs.sops;
  sopsFolder = ./../../../../secrets;
in
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  options.${namespace}.programs.sops = with types; {
    enable = mkBoolOpt false "Enable sops for NixOS";
  };

  config = mkIf cfg.enable {
    sops = {
      # Use host-specific secrets file
      defaultSopsFile = "${sopsFolder}/${config.networking.hostName}.yaml";
      validateSopsFiles = false;
      age = {
        # automatically import host SSH keys as age keys
        sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      };
      # secrets will be output to /run/secrets
      # e.g. /run/secrets/msmtp-password
      # secrets required for user creation are handled in respective ./users/<username>.nix files
      # because they will be output to /run/secrets-for-users and only when the user is assigned to a host.
    };

    environment.systemPackages = with pkgs; [ sops yq age ];

    # For home-manager a separate age key is used to decrypt secrets and must be placed onto the host. This is because
    # the user doesn't have read permission for the ssh service private key. However, we can bootstrap the age key from
    # the secrets decrypted by the host key, which allows home-manager secrets to work without manually copying over
    # the age key.
   
  };
} 