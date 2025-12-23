# MacTahoe GTK theme
{
  lib,
  stdenv,
  fetchFromGitHub,
  dialog,
  glib,
  gnome-themes-extra,
  jdupes,
  libxml2,
  sassc,
  util-linux,
  altVariants ? [ ], # normal|alt|all
  colorVariants ? [ ], # light|dark
  opacityVariants ? [ ], # normal|solid
  themeVariants ? [ ], # default|blue|purple|pink|red|orange|yellow|green|grey|all
  schemeVariants ? [ ], # standard|nord
  iconVariant ? null, # apple|simple|gnome|ubuntu|tux|arch|manjaro|fedora|debian|void|opensuse|popos|mxlinux|zorin|budgie|gentoo
  panelOpacity ? null, # default|30|45|60|75
  panelSize ? null, # default|smaller|bigger
  roundedMaxWindow ? false,
  darkerColor ? false,
  withBlur ? false, # Install blur version (requires blur-my-shell extension)
}:

let
  pname = "mactahoe-gtk-theme";
  single = x: lib.optional (x != null) x;
in

lib.checkListOfEnum "${pname}: window control button variants" [ "normal" "alt" "all" ] altVariants
lib.checkListOfEnum "${pname}: color variants" [ "light" "dark" ] colorVariants
lib.checkListOfEnum "${pname}: opacity variants" [ "normal" "solid" ] opacityVariants
lib.checkListOfEnum "${pname}: theme accent variants"
  [
    "default"
    "blue"
    "purple"
    "pink"
    "red"
    "orange"
    "yellow"
    "green"
    "grey"
    "all"
  ]
  themeVariants
lib.checkListOfEnum "${pname}: scheme variants" [ "standard" "nord" ] schemeVariants
lib.checkListOfEnum "${pname}: icon variants"
  [
    "standard"
    "apple"
    "simple"
    "gnome"
    "ubuntu"
    "tux"
    "arch"
    "manjaro"
    "fedora"
    "debian"
    "void"
    "opensuse"
    "popos"
    "mxlinux"
    "zorin"
    "budgie"
    "gentoo"
  ]
  (single iconVariant)
lib.checkListOfEnum "${pname}: panel opacity" [ "default" "30" "45" "60" "75" ] (single panelOpacity)
lib.checkListOfEnum "${pname}: panel size" [ "default" "smaller" "bigger" ] (single panelSize)

stdenv.mkDerivation rec {
  inherit pname;
  version = "2025-11-29";

  src = fetchFromGitHub {
    owner = "vinceliuice";
    repo = "MacTahoe-gtk-theme";
    rev = "0c678623decb8ed65e1a54376bfa036525e37c92";
    hash = "sha256-9Lp0SLZd8duDyqoWMPfSZmdzNT5DXEwsfq071MWpmIU=";
  };

  nativeBuildInputs = [
    dialog
    glib
    jdupes
    libxml2
    sassc
    util-linux
  ];

  buildInputs = [ gnome-themes-extra ];

  postPatch = ''
    find -name "*.sh" -print0 | while IFS= read -r -d ''' file; do
      patchShebangs "$file"
    done

    # Do not provide sudo, not needed in Nix build
    substituteInPlace libs/lib-core.sh --replace-fail '$(which sudo)' false

    # Provide dummy home directory
    substituteInPlace libs/lib-core.sh \
      --replace-fail 'MY_HOME=$(getent passwd "''${MY_USERNAME}" | cut -d: -f6)' 'MY_HOME=/tmp'
  '';

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/themes

    ./install.sh \
      ${toString (map (x: "--alt " + x) altVariants)} \
      ${toString (map (x: "--color " + x) colorVariants)} \
      ${toString (map (x: "--opacity " + x) opacityVariants)} \
      ${toString (map (x: "--theme " + x) themeVariants)} \
      ${toString (map (x: "--scheme " + x) schemeVariants)} \
      ${lib.optionalString roundedMaxWindow "--roundedmaxwindow"} \
      ${lib.optionalString darkerColor "--darkercolor"} \
      ${lib.optionalString withBlur "--blur"} \
      ${lib.optionalString (iconVariant != null) ("--gnome-shell -i " + iconVariant)} \
      ${lib.optionalString (panelSize != null) ("--gnome-shell -panelheight " + panelSize)} \
      ${lib.optionalString (panelOpacity != null) ("--gnome-shell -panelopacity " + panelOpacity)} \
      --dest $out/share/themes

    jdupes --quiet --link-soft --recurse $out/share

    runHook postInstall
  '';

  meta = {
    description = "MacOS Tahoe like GTK theme based on Elegant Design";
    homepage = "https://github.com/vinceliuice/MacTahoe-gtk-theme";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    maintainers = [ ];
  };
}
