# Configure the perSystem `pkgs` argument once, with unfree allowed.
#
# Without this, modules that need unfree packages at flake-output build time
# (devShells, packages, apps) each call `import inputs.nixpkgs { ... config.allowUnfree = true; }`
# separately. Each re-import instantiates the full nixpkgs attrset tree, which
# costs evaluation time. Sharing one instance across perSystem callers removes
# that duplication.
{ inputs, ... }:
{
  perSystem =
    { system, ... }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    };
}
