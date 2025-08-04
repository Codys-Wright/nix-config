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
  cfg = config.${namespace}.app.browser.brave;
in
{
  options.${namespace}.app.browser.brave = {
    enable = mkBoolOpt false "Enable Brave browser";
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
