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
    version = mkDefault "6_16";
  };

  config = mkIf cfg.enable {
    boot.kernelPackages = mkDefault (
      pkgs.linuxKernel.packages."linux_${cfg.version}"
    );
  };
} 