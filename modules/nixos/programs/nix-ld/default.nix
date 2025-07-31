{
  config,
  inputs,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.programs.nix-ld;
in
{
  options.${namespace}.programs.nix-ld = {
    enable = mkBoolOpt false "${namespace}.programs.nix-ld.enable";
  };

  config = mkIf cfg.enable {
    programs.nix-ld = {
      enable = true;
      # package = inputs.nix-ld-rs.packages."${pkgs.system}".nix-ld-rs;
    };
  };
}
