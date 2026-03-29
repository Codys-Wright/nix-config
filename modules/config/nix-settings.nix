{
  FTS,
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
          ];
          trusted-users = [
            "root"
            "@wheel"
            "@admin"
          ];
          substituters = [
            "https://cache.nixos.org/"
            "https://devenv.cachix.org"
            "https://fasttrackstudio.cachix.org"
            "https://microvm.cachix.org"
            "https://fleet.cachix.org"
          ];
          trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
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
  FTS.nix-settings = {
    description = "Shared nix settings and package policy";
    includes = [
      <FTS/nix>
      (<den/unfree> true)
    ];
    os = nixSettings;
  };
}
