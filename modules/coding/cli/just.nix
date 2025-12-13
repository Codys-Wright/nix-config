# Just - command runner
{
  FTS, ... }:
{
  FTS.coding._.cli._.just = {
    description = "Just command runner";

    # NixOS system packages
    nixos = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        just
      ];
    };

    # Darwin system packages
    darwin = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        just
      ];
    };
  };
}

