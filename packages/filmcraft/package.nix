{
  callPackage,
  alsa-lib,
  libva,
}:

callPackage ../_craft/mk-craft-app.nix { } {
  pname = "filmcraft";
  version = "0.14.0";
  hash = "sha256-2UvPxCyhRT7XMXZqX1aHArLuL0VUo3hC5a8q2WFph6w=";
  cargoHash = "sha256-uStVTwwZBP396uyBjdu+aF+zMqQVaZrn7cw14Nd2U4Y=";
  releaseDate = "2026-10-28";
  description = "Non-linear video editor, a free alternative to Premiere Pro";
  extraBuildInputs = [ alsa-lib ];
  # VA-API hardware decode; NVDEC/NVENC come from the driver runpath.
  extraRuntimeLibs = [ libva ];
}
