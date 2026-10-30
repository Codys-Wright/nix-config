# GUI API clients (Linux): Postman and Insomnia
{ ... }:
{
  fleet.coding._.tools._.api-clients = {
    description = "GUI API clients: Postman and Insomnia (Linux)";

    homeManager =
      { pkgs, lib, ... }:
      {
        home.packages = lib.optionals pkgs.stdenv.hostPlatform.isLinux (
          with pkgs;
          [
            postman
            insomnia
          ]
        );
      };
  };
}
