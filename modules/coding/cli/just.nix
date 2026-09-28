# Just - command runner
{
  fleet.coding._.cli._.just = {
    description = "Just command runner";

    provides.to-hosts.os =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          just
        ];
      };
  };
}
