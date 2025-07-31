{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.programs.brave;
in
{
  options.${namespace}.programs.brave = {
    enable = mkBoolOpt false "${namespace}.programs.brave.enable";
  };

  config = mkIf cfg.enable {
    programs.chromium = {
      enable = true;
      package = pkgs.brave;
      extensions = [
        { id = "nngceckbapebfimnlniiiahkandclblb"; } # Bitwarden
        { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; } # Dark Reader
        { id = "edibdbjcniadpccecjdfdjjppcpchdlm"; } # I still dont care about cookies
      ];
    };
  };
}
