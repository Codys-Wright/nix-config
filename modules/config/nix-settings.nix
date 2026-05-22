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
            # lazy-trees: skip copying flake source into /nix/store unless a build
            # actually needs it. Cuts wall-clock time on every eval, especially when
            # the working tree is dirty. Requires Nix >= 2.30.
            "lazy-trees"
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
