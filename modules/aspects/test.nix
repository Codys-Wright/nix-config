# Test module - demonstrates parametric aspect with named parameters
# Can add hello and/or cowsay packages based on configuration
#
# Usage:
#   (FTS.test { hello = true; cowsay = true; })
#   (FTS.test { hello = true; })  # Only hello
#   (FTS.test { })  # No packages (defaults)
{
  lib,
  FTS,
  ...
}:
{
  # Function that produces an aspect with configurable packages
  # Takes named parameters: { hello, cowsay, enable, ... }
  # Similar pattern to: FTS.system._.disk = { type, device, ... }
  FTS.test =
    {
      hello ? false,
      cowsay ? false,
      enable ? true,
      ...
    }@args:
    {
      description = "Test module that adds hello and/or cowsay packages based on configuration";

      nixos =
        { pkgs, lib, ... }:
        lib.mkIf enable {
          environment.systemPackages =
            with pkgs;
            lib.optional hello pkgs.hello ++ lib.optional cowsay pkgs.cowsay;
        };

      homeManager =
        { pkgs, lib, ... }:
        lib.mkIf enable {
          home.packages = with pkgs; lib.optional hello pkgs.hello ++ lib.optional cowsay pkgs.cowsay;
        };
    };
}
