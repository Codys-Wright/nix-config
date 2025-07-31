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
  cfg = config.${namespace}.config.apps;
in
{
  options.${namespace}.config.apps = with types; {
    enable = mkBoolOpt false "Enable default app config";
  };

  config = mkIf cfg.enable {
    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "application/pdf" = "okularApplication_pdf.desktop";
        "text/html" = "brave.desktop";
        "x-scheme-handler/http" = "brave.desktop";
        "x-scheme-handler/https" = "brave.desktop";
        "x-scheme-handler/about" = "brave.desktop";
        "x-scheme-handler/unknown" = "brave.desktop";
      };
    };
  };
}
