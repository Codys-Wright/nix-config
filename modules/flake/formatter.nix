# `nix fmt` for this repo.
#
# Nothing configured `perSystem.formatter`, so flake-parts still emitted a
# `formatter.<system>` output holding `null`. Newer flake-parts turns that into
# a hard `nix flake check` failure ("could not determine statically that no
# formatter is defined for *all* systems"). Define it properly instead of
# suppressing the attribute — this is the same nixfmt-rfc-style that
# `just fmt` and the pre-commit hook use, so `nix fmt` now matches them.
{ ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      formatter = pkgs.nixfmt-rfc-style;
    };
}
