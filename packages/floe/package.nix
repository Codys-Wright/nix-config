# Floe ships its own working Nix packaging (nix/package.nix) — pull the
# pinned source and delegate to it rather than reimplementing the Zig build.
{
  callPackage,
  fetchFromGitHub,
  zig_0_14,
}:
callPackage "${
  fetchFromGitHub {
    owner = "floe-audio";
    repo = "Floe";
    rev = "e19d845eb3947a3703a0899820816c7c4b9b0cc2";
    hash = "sha256-LMr8QcGEWgNp5771jddszMivfg1rfQCQg2Wisj2FEwo=";
  }
}/nix/package.nix" { inherit zig_0_14; }
