# GDM Display Manager
# GNOME Display Manager - commonly used with GNOME desktop
{
  den,
  FTS,
  ...
}:
{
  FTS.gdm = {
    description = "GNOME Display Manager (GDM)";

    nixos = { pkgs, lib, ... }: {
      # Enable GDM display manager
      services.displayManager.gdm.enable = true;
    };
  };
}

