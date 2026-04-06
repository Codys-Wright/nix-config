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
      (<den/user-shell> "bash")
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
          firefox
          vlc
        ];
      };
  };
}
