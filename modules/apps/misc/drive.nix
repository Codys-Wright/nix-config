# Drive (FastTrackStudios/drive): the agent CLI (`drive`) and the node
# (`drive-node`), at a release tag.
#
# No nixpkgs follows: the release pushes exactly these store paths (built
# from the tag's own flake.lock) to fasttrackstudio.cachix.org, so a switch
# downloads them and compiles nothing. Following our nixpkgs would make new
# paths no cache has.
#
# Bump: point the url at the new tag, `nix flake update drive`, switch.
{ inputs, lib, ... }:
{
  flake-file.inputs.drive.url = lib.mkDefault "github:FastTrackStudios/drive/v26.11.1";

  fleet.apps._.misc._.drive = {
    description = "Drive CLI (the agent, `drive`) from the release's Nix package";

    homeManager =
      { pkgs, lib, ... }:
      lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        home.packages = [ inputs.drive.packages.${pkgs.stdenv.hostPlatform.system}.drive ];
      };
  };
}
