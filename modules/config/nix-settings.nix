{
  fleet,
  den,
  __findFile,
  ...
}:
let
  nixSettings =
    { config, lib, ... }:
    {
      nix = {
        optimise.automatic = true;
        settings = {
          experimental-features = [
            "nix-command"
            "flakes"
            # NOTE: lazy-trees is Determinate-Nix-only (not upstream Nix). If you
            # ever switch nix.package to inputs.determinate, add "lazy-trees" here
            # for big wins on dirty-tree evals.
          ];
          trusted-users = [
            "root"
            "@wheel"
            "@admin"
          ];
          substituters = [
            "https://cache.nixos.org/"
            "https://fasttrackstudio.cachix.org"
            "https://microvm.cachix.org"
            "https://fleet.cachix.org"
          ];
          trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "fasttrackstudio.cachix.org-1:r7v7WXBeSZ7m5meL6w0wttnvsOltRvTpXeVNItcy9f4="
            "microvm.cachix.org-1:oXnAttsRgXtB2wXwwITVq3+NzJIhWQz9MKPAF8FcVPs="
            "fleet.cachix.org-1:OXtbUqSc/c0fVhiq9pBAmb/4eGVcfz7qlNWFmvQpNj8="
          ];
        };
        gc = lib.optionalAttrs config.nix.enable {
          automatic = true;
          options = "--delete-older-than 7d";
        };
      };
    };
in
{
  fleet.nix-settings = {
    description = "Shared nix settings and package policy";
    includes = [
      <fleet/nix>
    ];
    os = nixSettings;
  };
}
