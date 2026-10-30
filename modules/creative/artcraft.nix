# ArtCraft — storytold's Rust creative/office suite.
#
# Nine come from nixpkgs; FilmCraft, EffectCraft, DesignCraft and FigCraft
# are built from source in packages/ (packages/_craft/mk-craft-app.nix)
# until nixpkgs gains them.
{
  fleet.creative._.artcraft = {
    description = "ArtCraft suite: PhotoCraft, VectorCraft, FilmCraft, LightCraft, PdfCraft, EffectCraft, DesignCraft, FigCraft, WordCraft, SoundCraft, DeckCraft, CADCraft, GridCraft";

    homeManager =
      { pkgs, lib, ... }:
      {
        # Linux only: the from-source four are, and nixpkgs' soundcraft
        # claims darwin but pulls alsa-lib.
        home.packages = lib.optionals pkgs.stdenv.hostPlatform.isLinux (
          with pkgs;
          [
            photocraft # Photoshop
            vectorcraft # Illustrator
            filmcraft # Premiere Pro
            lightcraft # Lightroom
            pdfcraft # Acrobat
            effectcraft # After Effects
            designcraft # InDesign
            figcraft # Figma
            wordcraft # Word
            soundcraft # Pro Tools
            deckcraft # PowerPoint
            cadcraft # AutoCAD
            gridcraft # Excel
          ]
        );
      };
  };
}
