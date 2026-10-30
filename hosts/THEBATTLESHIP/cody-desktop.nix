# cody's Loft (github:Codys-Wright/loft) on THEBATTLESHIP: the niri-loft
# compositor, agent skills, phone, Spotify and the MacTahoe GTK base.
# Every user gets Loft itself from fleet.desktop._.loft.
{ inputs, ... }:
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
      spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      # Files (Nautilus): sort folders in with files, so "newest first" in
      # Downloads is one list, not folders then files (GTK 4 file chooser too).
      dconf.settings."org/gtk/gtk4/settings/file-chooser".sort-directories-first = false;

      programs.loft = {
        enable = true;
        # The `loft` (configuring Loft, window rules) and `loft-drive` agent
        # skills in ~/.claude/skills.
        agentSkills.enable = true;
        # Dolphin themed like Files' glass (Kvantum + a KDE colour scheme per
        # Loft theme, set in dolphinrc only — no global Qt style).
        qt.enable = true;
        # Must match the compositor (hosts/THEBATTLESHIP/niri-loft.nix): turns
        # on per-workspace wallpapers (the layer rule + the shell's surfaces).
        niriPackage =
          let
            loft = inputs.loft.packages.${pkgs.stdenv.hostPlatform.system};
          in
          loft.niri-loft-live or loft.niri-loft;
        gtkBase.dark = gtk4 "Dark";
        gtkBase.light = gtk4 "Light";
        # No auto-lock and no monitor power-off for now: turning the monitors off
        # (DPMS) wedged the NVIDIA driver (nvidia-modeset hung in D state) and the
        # desktop never woke up. Re-enable once that's solved.
        idle.lockAfter = null;
        idle.screenOffAfter = null;
        # iPhone via tether (tetherd user unit; Loft's Messages / notifications /
        # calls). The Loft feature stays off until paired (Settings → Features).
        phone.enable = true;
        # Spotify patched by Spicetify at runtime, so its colors follow the
        # Loft theme live (Cozytile's "text" theme + schemes, Marketplace).
        spotify = {
          enable = true;
          extensions = map (e: "${e.src}/${e.name}") (
            with spicePkgs.extensions;
            [
              adblock
              hidePodcasts
              shuffle
            ]
          );
        };
      };
      # Replaced by programs.loft.spotify (build-time Spicetify can't follow themes).
      programs.spicetify.enable = false;
    };
}
