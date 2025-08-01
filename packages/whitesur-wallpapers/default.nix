{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib,
  # You also have access to your flake's inputs.
  inputs,

  # The namespace used for your flake, defaulting to "internal" if not set.
  namespace,

  # All other arguments come from NixPkgs. You can use `pkgs` to pull packages or helpers
  # programmatically or you may add the named attributes as arguments here.
  pkgs,
  stdenv,
  ...
}: let
in
  stdenv.mkDerivation {
    pname = "whitesur-wallpapers";
    version = "2024-01-30";

    src = inputs.whitesur-wallpapers;

    installPhase = ''
      runHook preInstall

      # Create backgrounds directory
      mkdir --parents $out/share/backgrounds

      # Install all 4k wallpapers (main variants)
      cp --recursive 4k/*.jpg $out/share/backgrounds/

      # Install Nord wallpapers
      cp --recursive Wallpaper-nord/*.png $out/share/backgrounds/

      # Install other resolutions (1080p, 2k) for completeness
      mkdir --parents $out/share/backgrounds/1080p
      cp --recursive 1080p/*.jpg $out/share/backgrounds/1080p/

      mkdir --parents $out/share/backgrounds/2k
      cp --recursive 2k/*.jpg $out/share/backgrounds/2k/

      # Create symbolic links for common names
      cd $out/share/backgrounds
      
      # WhiteSur variants
      ln --symbolic WhiteSur-dark.jpg WhiteSur.jpg
      ln --symbolic WhiteSur-light.jpg WhiteSur-light.jpg
      
      # Monterey variants
      ln --symbolic Monterey-dark.jpg Monterey.jpg
      ln --symbolic Monterey-light.jpg Monterey-light.jpg
      
      # Ventura variants
      ln --symbolic Ventura-dark.jpg Ventura.jpg
      ln --symbolic Ventura-light.jpg Ventura-light.jpg
      
      # Sonoma variants
      ln --symbolic Sonoma-dark.jpg Sonoma.jpg
      ln --symbolic Sonoma-light.jpg Sonoma-light.jpg

      runHook postInstall
    '';

    meta = with lib; {
      description = "Beautiful macOS-inspired wallpapers including WhiteSur, Monterey, Ventura, Sonoma, and Nord variants";
      homepage = "https://github.com/vinceliuice/WhiteSur-wallpapers";
      license = licenses.gpl3Only;
      platforms = platforms.all;
      maintainers = with maintainers; [ ];
    };
  } 