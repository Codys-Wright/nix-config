# Set GNOME Files (Nautilus) as the default file manager and file picker
{ fleet, ... }:
{
  fleet.desktop._.environment._.gnome._.nautilus-default = {
    description = "Set Nautilus as the default file manager and file picker";

    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.nautilus ];
      };

    homeManager =
      { ... }:
      {
        xdg.mimeApps = {
          enable = true;
          defaultApplications = {
            "inode/directory" = "org.gnome.Nautilus.desktop";
            "x-scheme-handler/file" = "org.gnome.Nautilus.desktop";
          };
        };
      };
  };
}
