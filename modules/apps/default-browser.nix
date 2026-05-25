# Parametric aspect for setting the default browser via xdg.mimeApps
# Usage: (<fleet/apps/default-browser> "brave")
# Valid options: "brave" | "firefox" | "zen" | "chromium"
{ fleet, lib, ... }:
let
  desktopFiles = {
    brave = "brave-browser.desktop";
    firefox = "firefox.desktop";
    zen = "zen-twilight.desktop";
    chromium = "chromium-browser.desktop";
  };
  validOptions = lib.concatStringsSep ", " (builtins.attrNames desktopFiles);
in
{
  fleet.apps._.default-browser.__functor =
    _self: browser:
    { class, aspect-chain }:
    let
      desktop =
        desktopFiles.${browser}
          or (throw "default-browser: unknown browser '${browser}'. Valid options: ${validOptions}");
    in
    {
      # xdg.mimeApps is a linux-only home-manager module; omit it entirely on
      # darwin (e.g. voyager) so the shared cody aspect still evaluates there.
      homeManager =
        { pkgs, ... }:
        lib.mkIf pkgs.stdenv.isLinux {
          xdg.mimeApps = {
            enable = true;
            defaultApplications = {
              "text/html" = desktop;
              "x-scheme-handler/http" = desktop;
              "x-scheme-handler/https" = desktop;
              "x-scheme-handler/ftp" = desktop;
              "application/xhtml+xml" = desktop;
              "application/x-extension-htm" = desktop;
              "application/x-extension-html" = desktop;
              "application/x-extension-xhtml" = desktop;
              "application/x-extension-xht" = desktop;
            };
          };
        };
    };
}
