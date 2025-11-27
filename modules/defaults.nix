{
  inputs,
  den,
  lib,
  ...
}:
{
   # default.{host,user,home} aspects can be used for global settings.
  den.default = {
    darwin.system.stateVersion = 6;
    nixos.system.stateVersion = "25.11";
    homeManager.home.stateVersion = "25.11";
    
    # Enable unfree packages
    nixos.nixpkgs.config.allowUnfree = true;
    homeManager.nixpkgs.config.allowUnfree = true;
  };

}