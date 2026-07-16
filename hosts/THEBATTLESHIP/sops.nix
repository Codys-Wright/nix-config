{ inputs, den, ... }:
{
  den.aspects.THEBATTLESHIP-sops = {
    description = "Host sops-nix wiring: cody age-key bootstrap, davfs2/proton/codeberg secrets + templates";
    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        # SOPS secrets
        imports = [ inputs.sops-nix.nixosModules.default ];
        sops = {
          defaultSopsFile = "${inputs.nix-secrets}/sops/users/cody.yaml";
          validateSopsFiles = false;
          age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
          # Bootstrap cody's age key from the host secret so home-manager
          # sops works without manually copying sops.key around.
          secrets."keys/age" = {
            sopsFile = "${inputs.nix-secrets}/sops/hosts/THEBATTLESHIP.yaml";
            owner = "cody";
            path = "/home/cody/.config/sops/age/keys.txt";
          };
          secrets."cody/nextcloud/davfs2-secrets" = {
            owner = "root";
            group = "root";
            mode = "0400";
          };
          secrets."cody/proton/privatekey" = {
            owner = "root";
            group = "root";
            mode = "0400";
          };

          # FastTrackStudio Codeberg agent credentials.
          # Codeberg API/git access token — decrypted to a file owned by cody.
          secrets."cody/codeberg/fts-codeberg-access-token" = {
            owner = "cody";
            group = "users";
            mode = "0400";
          };
          # Dedicated SSH key for the fts-agent Codeberg account (the public
          # half is registered on that account). Used as an SSH IdentityFile.
          secrets."cody/codeberg/fts-agent" = {
            owner = "cody";
            group = "users";
            mode = "0400";
          };

          # Render the token into a dotenv file so any service can pull it in
          # via `serviceConfig.EnvironmentFile`, and it's available to source
          # for ad-hoc use — without the value ever landing in the nix store.
          # Path: config.sops.templates."fts-codeberg.env".path
          templates."fts-codeberg.env" = {
            content = ''
              FTS_CODEBERG_ACCESS_TOKEN=${config.sops.placeholder."cody/codeberg/fts-codeberg-access-token"}
              FTS_CODEBERG_GIT_URL=https://fts-agent:${
                config.sops.placeholder."cody/codeberg/fts-codeberg-access-token"
              }@codeberg.org
            '';
            owner = "cody";
            group = "users";
            mode = "0400";
          };
        };
      };
  };
}
