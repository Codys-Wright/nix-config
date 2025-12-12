{
  inputs,
  den,
  pkgs,
  lib,
  FTS,
  __findFile,
  ...
}: {
  den = {
    homes = {
      # Darwin (macOS) home configuration
      aarch64-darwin.starcommand = {
        userName = "starcommand";
        aspect = "starcommand";
      };

      # NixOS home configuration
      x86_64-linux.starcommand = {
        userName = "starcommand";
        aspect = "starcommand";
      };
    };

    # starcommand user aspect
    # This is a service user for self-hosting infrastructure, not a personal user
    # Any host that includes this user automatically gets all self-hosting services
    #
    # Note: Hosts including this user should set their instantiate function to use
    # selfhostblocks' patched nixpkgs:
    #   instantiate = args: inputs.selfhostblocks.lib.${system}.patchedNixpkgs.nixosSystem (args // { inherit system; });
    aspects.starcommand = {
      description = "Self-hosting services user (starcommand)";

      includes = [
        # Include the FTS.selfhost module which has all the SelfHostBlocks configuration
        (FTS.selfhost {})
      ];
    };
  };
}
