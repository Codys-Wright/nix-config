# mioctl — CLI for configuring iConnectivity Mio X-series MIDI interfaces
# (the studio mioXM) from Linux, where iConnectivity's Auracle doesn't run.
{ fleet, ... }:
{
  fleet.music._.production._.mioctl = {
    description = "mioctl CLI for iConnectivity mioXM/mioXL MIDI routers";

    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [
          (pkgs.callPackage ../../../packages/mioctl/mioctl.nix { })
        ];
      };
  };
}
