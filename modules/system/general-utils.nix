# General utility packages available as a standalone aspect
{ fleet, ... }:
{
  fleet.utils = {
    description = "General utility packages (unrar, etc.)";
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          unrar
        ];
      };
  };
}
