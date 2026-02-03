# Global Window Rules
# Applied to all window-rules presets
{
  name = "global";
  settings = {
    # Basic window behavior rules
    windowrule = [
      # Floating windows
      "class:(pavucontrol), float"
      "class:(blueman-manager), float"
      "class:(nm-connection-editor), float"
      "title:(Save File), float"
      "title:(Open File), float"
      "title:(Select File), float"

      # Picture-in-picture and popups
      "title:(Picture-in-Picture), float"
      "title:(Picture-in-Picture), pin"
      "class:(xdg-desktop-portal-gtk), float"

      # Utility windows
      "class:(zenity), float"
      "class:(org.gnome.Calculator), float"
      "class:(gnome-calculator), float"

      # Gaming and media
      "class:(steam_app.*), fullscreen"
      "class:(steam), title:(Friends List), float"
      "class:(steam), title:(Steam Settings), float"
    ];
  };
}