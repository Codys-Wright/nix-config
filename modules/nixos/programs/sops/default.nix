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
  sopsFolder = ./../../../../secrets/sops;
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

    # For home-manager a separate age key is used to decrypt secrets and must be placed onto the host. This is because
    # the user doesn't have read permission for the ssh service private key. However, we can bootstrap the age key from
    # the secrets decrypted by the host key, which allows home-manager secrets to work without manually copying over
    # the age key.
    sops.secrets = lib.mkMerge [
      {
        # These age keys are are unique for the user on each host and are generated on their own (i.e. they are not derived
        # from an ssh key).

        "keys/age" = {
          owner = "cody";
          group = "users";
          # We need to ensure the entire directory structure is that of the user...
          path = "/home/cody/.config/sops/age/keys.txt";
        };
        # extract password/username to /run/secrets-for-users/ so it can be used to create the user
        "passwords/cody" = {
          sopsFile = "${sopsFolder}/shared.yaml";
          neededForUsers = true;
        };
        "passwords/msmtp" = {
          sopsFile = "${sopsFolder}/shared.yaml";
        };
      }
      # only reference borg password if host is using backup
      (lib.mkIf config.services.backup.enable {
        "passwords/borg" = {
          owner = "root";
          group = if pkgs.stdenv.isLinux then "root" else "wheel";
          mode = "0600";
          path = "/etc/borg/passphrase";
        };
      })
    ];
    # The containing folders are created as root and if this is the first ~/.config/ entry,
    # the ownership is busted and home-manager can't target because it can't write into .config...
    # FIXME(sops): We might not need this depending on how https://github.com/Mic92/sops-nix/issues/381 is fixed
    system.activationScripts.sopsSetAgeKeyOwnership =
      let
        ageFolder = "/home/cody/.config/sops/age";
        user = "cody";
        group = "users";
      in
      ''
        mkdir -p ${ageFolder} || true
        chown -R ${user}:${group} /home/cody/.config
      '';
  };
} 