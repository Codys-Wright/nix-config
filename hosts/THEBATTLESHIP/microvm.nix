# MicroVM for testing THEBATTLESHIP — graphical niri desktop
# Run with: nix run .#THEBATTLESHIP-vm
# SSH: ssh -p 2222 root@localhost (password: root)
# Login: cody (password: cody)
{
  fleet,
  __findFile,
  ...
}:
{
  den.hosts.x86_64-linux.THEBATTLESHIP-vm = {
    description = "THEBATTLESHIP MicroVM — graphical niri desktop for local testing";
    users.cody = { };
    aspect = "THEBATTLESHIP-vm";
  };

  den.aspects.THEBATTLESHIP-vm = {
    includes = [
      (fleet.system._.microvm { graphics = true; })
      <fleet.desktop/environment/niri>
      (fleet.coding {
        editor = {
          default = "nvf";
        };
        terminal = {
          default = "ghostty";
        };
        shell = {
          default = "fish";
        };
      })
    ];

    nixos =
      { ... }:
      {
        time.timeZone = "America/Los_Angeles";
      };
  };
}
