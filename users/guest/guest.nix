{
  fleet,
  den,
  __findFile,
  ...
}:
{
  den.homes.x86_64-linux.guest = {
    userName = "guest";
  };

  den.aspects.guest = {
    description = "Guest user — KDE Plasma desktop, minimal setup";

    includes = [
      den.aspects.hm-backup
      <den/primary-user>
      (<den/user-shell> "bash")
    ];

    nixos =
      { ... }:
      {
        users.users.guest = {
          isNormalUser = true;
          description = "Guest";
          extraGroups = [ "networkmanager" ];
          password = ""; # passwordless login
        };
      };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          firefox
          vim
          htop
          git
        ];
      };
  };
}
