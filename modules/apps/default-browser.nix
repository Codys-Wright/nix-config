# Parametric aspect for setting the default browser via xdg.mimeApps
# Usage: (<fleet/apps/default-browser> { desktop = "brave-browser.desktop"; })
{ fleet, ... }:
{
  fleet.apps._.default-browser.__functor =
    _self:
    { desktop }:
    { class, aspect-chain }:
    {
      homeManager =
        { ... }:
        {
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
