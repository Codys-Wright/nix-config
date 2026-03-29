# Just - command runner
{
  FTS.coding._.cli._.just = {
    description = "Just command runner";

    os =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          just
        ];
      };
  };
}
