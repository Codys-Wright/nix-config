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

    # NixOS-only (darwin has no systemd).
    nixos =
      { config, lib, ... }:
      {
        # crates.io answers 403 to any User-Agent shaped like
        # `curl/<version>`, and nixpkgs' fetchurl introduces itself as
        # "curl/8.18.0 Nixpkgs/26.11". Every crate tarball not already in
        # the store therefore fails to download:
        #
        #   trying https://crates.io/api/v1/crates/toml_edit/0.25.3+.../download
        #   curl: (22) The requested URL returned error: 403
        #   error: cannot download crate-toml_edit-... from any mirror
        #
        # It hits anything vendoring crates through nix — importCargoLock,
        # crane, fetchCrate — and it reads like a dependency problem in
        # whatever happened to be building. It is what actually stopped
        # THEBATTLESHIP rebuilding (via fts-rigs → reaper-launcher).
        #
        # Dropping the version is enough; bare "Nixpkgs" is accepted.
        # fetchurl declares NIX_CURL_FLAGS impure precisely so a host can
        # do this. Remove once nixpkgs stops sending a `curl/` UA.
        systemd.services.nix-daemon.environment.NIX_CURL_FLAGS =
          lib.mkIf config.nix.enable "--user-agent Nixpkgs";
      };
  };
}
