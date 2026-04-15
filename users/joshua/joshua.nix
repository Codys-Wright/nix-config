{
  fleet,
  den,
  __findFile,
  ...
}:
{
  den.homes.x86_64-linux.joshua = {
    userName = "joshua";
    aspect = "joshua";
  };

  den.aspects.joshua = {
    description = "Joshua user — KDE Plasma desktop";

    includes = [
      den.aspects.hm-backup
      <den/primary-user>

      # Coding
      (fleet.coding {
        editor = {
          default = "nvf";
        };
        terminal = {
          default = "ghostty";
        };
        shell = {
          default = "bash";
        };
      })
      (fleet.git-identity {
        name = "Zedonate";
        email = "skwish86@icloud.com";
      })

      <fleet.coding._.tools/game-dev>

      # Browsers
      <fleet.apps/browsers>
      (<fleet.apps/default-browser> "brave")
      (<fleet.apps/default-file-manager> "nautilus")

      # Utilities
      <fleet.apps._.misc/flameshot>
      <fleet.apps._.misc/localsend>
      <fleet.apps/flatpaks>
    ];

    nixos =
      { ... }:
      {
        users.users.joshua = {
          isNormalUser = true;
          description = "Joshua";
          extraGroups = [ "networkmanager" ];
          hashedPassword = "$6$cRP5cjenpjJ2dtcB$s8Hhnvk8Ro7INZasS2nP3OZyBrno/IkfpdSMlBFuDQ6LjloH6l4PMYMYK9jocj0gkXQoawqK1mUJEVHds/P1n.";
        };
      };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          vlc
        ];
      };
  };
}
