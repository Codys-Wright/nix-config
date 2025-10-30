{
  inputs,
  den,
  lib,
  ...
}:
{
   # default.{host,user,home} aspects can be used for global settings.
  den.default = {
    host.darwin.system.stateVersion = 6;
    host.nixos.system.stateVersion = "25.11";
    home.homeManager.home.stateVersion = "25.11";
    
    # Enable unfree packages
    host.darwin.nixpkgs.config.allowUnfree = true;
    host.nixos.nixpkgs.config.allowUnfree = true;
    home.homeManager.nixpkgs.config.allowUnfree = true;
  };

}