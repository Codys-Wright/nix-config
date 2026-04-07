# Spicetify — themed Spotify client with extensions
{
  fleet,
  inputs,
  ...
}:
{
  flake-file.inputs.spicetify-nix.url = "github:Gerg-L/spicetify-nix";
  flake-file.inputs.spicetify-nix.inputs.nixpkgs.follows = "nixpkgs";

  fleet.music._.production._.spicetify = {
    description = "Spotify client with Catppuccin theme, adblock, and extensions via spicetify-nix";

    homeManager =
      { pkgs, ... }:
      let
        spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
      in
      {
        programs.spicetify = {
          enable = true;
          theme = spicePkgs.themes.catppuccin;
          colorScheme = "mocha";

          enabledExtensions = with spicePkgs.extensions; [
            adblock
            hidePodcasts
            shuffle
          ];
        };
      };
  };
}
