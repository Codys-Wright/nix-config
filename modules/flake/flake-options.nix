{ lib, ... }:
{
  # Declares the flake.wrapperModules option used by wrapped program packages.
  # Each entry is a wrapper module consumed by inputs.wrapper-modules.wrappers.<name>.wrap.
  options.flake.wrapperModules = lib.mkOption {
    type = lib.types.attrsOf lib.types.unspecified;
    default = { };
    description = "Wrapper modules for wrapped program packages (BirdeeHub/nix-wrapper-modules).";
  };
}
