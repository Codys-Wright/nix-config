# Game development tools aspect
{
  fleet,
  ...
}:
{
  fleet.coding._.tools._.game-dev = {
    description = "Game development tools — Godot engine and Blender (CUDA build on NVIDIA hosts)";

    homeManager =
      {
        pkgs,
        lib,
        osConfig ? { },
        ...
      }:
      let
        # pkgsCuda.blender ships Cycles CUDA/OptiX kernels; the stock build has none for
        # RTX 40xx (sm_89) and fails to JIT them. It is prebuilt on cache.nixos-cuda.org,
        # which <fleet.hardware/cuda> adds as a substituter, so it is never built locally.
        # osConfig: the NixOS host's config (absent on darwin/standalone homes).
        nvidia = lib.elem "nvidia" (osConfig.services.xserver.videoDrivers or [ ]);
        blender = if nvidia then pkgs.pkgsCuda.blender else pkgs.blender;
      in
      {
        home.packages = [
          pkgs.godot_4
          blender
        ];
      };
  };
}
