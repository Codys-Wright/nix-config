# Parametric aspect for setting the default file manager via xdg.mimeApps
# Usage: (<fleet/apps/default-file-manager> { desktop = "org.gnome.Nautilus.desktop"; })
{ fleet, ... }:
{
  fleet.apps._.default-file-manager.__functor =
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
              "inode/directory" = desktop;
              "x-scheme-handler/file" = desktop;
            };
          };
        };
    };
}
