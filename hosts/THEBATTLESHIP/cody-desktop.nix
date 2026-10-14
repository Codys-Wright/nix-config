# cody's desktop on THEBATTLESHIP: Loft (github:Codys-Wright/loft)
# as the niri shell. The other users keep the host's shell (Noctalia) and the
# login screen stays the host's — this is cody's alone.
{ ... }:
{
  den.aspects."cody@THEBATTLESHIP".homeManager =
    { pkgs, ... }:
    let
      # MacTahoe's libadwaita CSS (the `-l` install) as the GTK 4 base under
      # Loft's theme: Tahoe toolbars and buttons; Loft keeps the palette and
      # the Golden Gate glass sidebar.
      mactahoe = pkgs.mactahoe-gtk-theme.override {
        colorVariants = [
          "dark"
          "light"
        ];
        themeVariants = [ "blue" ];
        withBlur = true;
      };
      gtk4 = variant: "${mactahoe}/share/themes/MacTahoe-${variant}-blue/gtk-4.0/gtk.css";
    in
    {
      programs.loft = {
        enable = true;
        gtkBase.dark = gtk4 "Dark";
        gtkBase.light = gtk4 "Light";
        # No auto-lock and no monitor power-off for now: turning the monitors off
        # (DPMS) wedged the NVIDIA driver (nvidia-modeset hung in D state) and the
        # desktop never woke up. Re-enable once that's solved.
        idle.lockAfter = null;
        idle.screenOffAfter = null;
      };
    };
}
