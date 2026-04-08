# Parametric aspect for setting the default file manager via xdg.mimeApps
# Usage: (<fleet/apps/default-file-manager> "nautilus")
# Valid options: "nautilus" | "dolphin" | "thunar" | "nemo"
{ fleet, lib, ... }:
let
  desktopFiles = {
    nautilus = "org.gnome.Nautilus.desktop";
    dolphin = "org.kde.dolphin.desktop";
    thunar = "thunar.desktop";
    nemo = "nemo.desktop";
  };
  validOptions = lib.concatStringsSep ", " (builtins.attrNames desktopFiles);
in
{
  fleet.apps._.default-file-manager.__functor =
    _self: fileManager:
    { class, aspect-chain }:
    let
      desktop =
        desktopFiles.${fileManager}
          or (throw "default-file-manager: unknown file manager '${fileManager}'. Valid options: ${validOptions}");
    in
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
