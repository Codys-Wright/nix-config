# Global Window Rules
# Applied to all window-rules presets
# Updated for Hyprland 0.53+ syntax
{
  name = "global";
  settings = {
    # Basic window behavior rules
    windowrule = [
      # Floating windows
      "float on, match:class pavucontrol"
      "float on, match:class blueman-manager"
      "float on, match:class nm-connection-editor"
      "float on, match:title (Save File)"
      "float on, match:title (Open File)"
      "float on, match:title (Select File)"

      # Picture-in-picture and popups
      "float on, match:title Picture-in-Picture"
      "pin on, match:title Picture-in-Picture"
      "float on, match:class xdg-desktop-portal-gtk"

      # Utility windows
      "float on, match:class zenity"
      "float on, match:class org.gnome.Calculator"
      "float on, match:class gnome-calculator"

      # Gaming and media
      "fullscreen on, match:class steam_app.*"
      "float on, match:class steam, match:title Friends List"
      "float on, match:class steam, match:title Steam Settings"
    ];
  };
}
