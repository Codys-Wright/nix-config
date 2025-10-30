# Example standalone home-manager configurations.
# These are independent of any host configuration.
# See documentation at <den>/nix/types.nix
{
  den.homes.x86_64-linux.cody = { };
  den.homes.aarch64-darwin.cody = {
    userName = "cody";
    aspect = "developer";
  };

 

}
