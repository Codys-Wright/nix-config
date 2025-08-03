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
let
  cfg = config.${namespace}.system.kernel;
in
{
  options.${namespace}.system.kernel = with types; {
    enable = mkBoolOpt false "Enable kernel configuration";
  };

  config = mkIf cfg.enable {
    boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_16;
  };
} 