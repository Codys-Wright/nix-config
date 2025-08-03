{
  options,
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
{
  options.${namespace}.gpu = with types; {
    enable = mkBoolOpt false "Enable GPU configuration";
    type = mkOpt (enum [ "nvidia" "amdgpu" "intel" ]) "nvidia" "GPU type to use";
  };
} 