# Just - command runner
{
  FTS, ... }:
{
  FTS.just = {
    description = "Just command runner";

    # NixOS system packages
    nixos = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        just
      ];
    };
  };
}

