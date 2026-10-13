# Floe ships its own working Nix packaging (nix/package.nix) — pull the
# pinned source and delegate to it rather than reimplementing the Zig build.
{
  applyPatches,
  callPackage,
  fetchFromGitHub,
  zig_0_14,
}:
let
  src = applyPatches {
    name = "floe-source";
    src = fetchFromGitHub {
      owner = "floe-audio";
      repo = "Floe";
      rev = "e19d845eb3947a3703a0899820816c7c4b9b0cc2";
      hash = "sha256-LMr8QcGEWgNp5771jddszMivfg1rfQCQg2Wisj2FEwo=";
    };
    # Bitbucket regenerated pffft's /get/<rev>.zip, so the archive's flat
    # hash changed (still stale upstream as of 2026-10). The unpacked tree
    # is what zig checks against build.zig.zon, so only the fetch hash moves.
    postPatch = ''
      substituteInPlace build.zig.zon.nix --replace-fail \
        "sha256-AylL4pp3KsUV19Xwe/R1sQ/mRN8TL/Vt7koYM452dTM=" \
        "sha256-ezEhumdSntAy0NnYj3oOy3t+yoHBi5iE5EEcvWE1utg="
    '';
  };
in
callPackage "${src}/nix/package.nix" { inherit zig_0_14; }
