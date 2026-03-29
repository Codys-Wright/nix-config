# Nushell shell aspect
{
  FTS,
  ...
}:
{
  FTS.coding._.shells._.nushell = {
    description = "Nushell shell package";

    os =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          nushell
        ];
      };

    homeManager =
      { pkgs, ... }:
      {
        programs.nushell = {
          enable = true;
        };
      };
  };
}
