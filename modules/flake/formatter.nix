# `nix fmt` — nixfmt over the tree (same formatter as `just fmt` and the
# pre-commit hook). Defining it for every system also lets flake-parts'
# `formatter` output pass `nix flake check`.
{
  perSystem =
    { pkgs, ... }:
    {
      formatter = pkgs.nixfmt-tree;
    };
}
