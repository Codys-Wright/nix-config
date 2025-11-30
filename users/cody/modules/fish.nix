{ inputs, ... }:
{
  cody.fish.homeManager =
    { pkgs, lib, ... }:
    let
      # Path to the _fish directory
      fishDir = ../dots/_fish;
    in
    {
      # Link tv.fish completion file
      home.file.".config/fish/conf.d/tvtab.fish".source = "${fishDir}/tv.fish";

      # Augment fish config - don't set enable, just add user-specific configuration
      # This will merge with FTS.fish configuration
      programs.fish = {
        # Import functions, aliases, and abbrs from _fish directory
        functions = import "${fishDir}/functions.nix" { inherit inputs lib; };
        shellAliases = import "${fishDir}/aliases.nix";
        shellAbbrs = import "${fishDir}/abbrs.nix";
      };
    };
}

