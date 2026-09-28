{ __findFile, ... }:
{
  den.homes.x86_64-linux.guest = {
    userName = "guest";
  };

  den.aspects.guest = {
    description = "Guest user — KDE Plasma desktop, minimal setup";

    includes = [
      (<den/user-shell> "bash")
    ];

    user = {
      description = "Guest";
      extraGroups = [ "networkmanager" ];
      password = ""; # passwordless login
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
