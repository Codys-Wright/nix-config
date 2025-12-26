# Global Window Rules
# Applied to all window-rules presets
{
  name = "global";
  settings = {
    # Basic window behavior rules
    windowrulev2 = [
      # Floating windows
      "float, class:(pavucontrol)"
      "float, class:(blueman-manager)"
      "float, class:(nm-connection-editor)"
      "float, title:(Save File)"
      "float, title:(Open File)"
      "float, title:(Select File)"

      # Picture-in-picture and popups
      "float, title:(Picture-in-Picture)"
      "pin, title:(Picture-in-Picture)"
      "float, class:(xdg-desktop-portal-gtk)"

      # Utility windows
      "float, class:(zenity)"
      "float, class:(org.gnome.Calculator)"
      "float, class:(gnome-calculator)"

      # Gaming and media
      "fullscreen, class:(steam_app.*)"
      "float, class:(steam), title:(Friends List)"
      "float, class:(steam), title:(Steam Settings)"
    ];
  };
}