# pi-coding-agent - coding agent CLI (provides `pi`)
{
  fleet.coding._.cli._.pi-coding-agent = {
    description = "pi-coding-agent — coding agent CLI";

    os =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          pi-coding-agent
        ];
      };
  };
}
