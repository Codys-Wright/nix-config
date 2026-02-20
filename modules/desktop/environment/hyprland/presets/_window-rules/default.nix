# Default Window Rules - Comprehensive base rules
# Updated for Hyprland 0.53+ syntax
{
  name = "default";
  settings = {
    # Picture-in-Picture - universal floating video
    windowrule = [
      "float on, match:title ^(Picture-in-Picture)$"
      "pin on, match:title ^(Picture-in-Picture)$"
      "size 640 360, match:title ^(Picture-in-Picture)$"
      "move 72% 7%, match:title ^(Picture-in-Picture)$"
      "keep_aspect_ratio on, match:title ^(Picture-in-Picture)$"
      "opacity 0.95 0.75, match:title ^(Picture-in-Picture)$"

      # File dialogs - float and center
      "float on, match:title ^(Open File)$"
      "float on, match:title ^(Save File)$"
      "float on, match:title ^(Save As)$"
      "size 70% 60%, match:title ^(Save As)$"
      "center on, match:title ^(Save As)$"
      "float on, match:initial_title ^(Open Files)$"
      "size 70% 60%, match:initial_title ^(Open Files)$"

      # Authentication dialogs
      "float on, match:title ^(Authentication Required)$"
      "center on, match:title ^(Authentication Required)$"

      # Calculator
      "float on, match:class ^(org.gnome.Calculator)$"
      "float on, match:class ^([Qq]alculate-gtk)$"

      # Browsers - opacity
      "opacity 0.99 0.8, match:class ^([Ff]irefox|org.mozilla.firefox|[Ff]irefox-esr)$"
      "opacity 0.99 0.8, match:class ^([Gg]oogle-chrome(-beta|-dev|-unstable)?)$"
      "opacity 0.99 0.8, match:class ^([Cc]hromium)$"
      "opacity 0.99 0.8, match:class ^([Mm]icrosoft-edge(-stable|-beta|-dev)?)$"
      "opacity 0.99 0.8, match:class ^(Brave-browser(-beta|-dev)?)$"
      "opacity 0.99 0.8, match:class ^(zen-alpha|zen)$"

      # Terminals - opacity
      "opacity 0.9 0.7, match:class ^(Alacritty|kitty|kitty-dropterm)$"

      # Communication - opacity
      "opacity 0.94 0.86, match:class ^([Dd]iscord|[Ww]ebCord|[Vv]esktop)$"
      "opacity 0.94 0.86, match:class ^([Ff]erdium)$"
      "opacity 0.94 0.86, match:class ^([Ww]hatsapp-for-linux)$"
      "opacity 0.94 0.86, match:class ^(org.telegram.desktop|io.github.tdesktop_x64.TDesktop)$"
      "opacity 0.94 0.86, match:class ^(Element)$"

      # Development - opacity
      "opacity 0.9 0.8, match:class ^(codium|codium-url-handler|VSCodium)$"
      "opacity 0.9 0.8, match:class ^(VSCode|code|code-url-handler)$"
      "opacity 0.9 0.8, match:class ^(jetbrains-.+)$"

      # File managers - opacity
      "opacity 0.9 0.8, match:class ^([Tt]hunar|org.gnome.Nautilus|[Pp]cmanfm-qt)$"

      # Settings/utilities - float and opacity
      "float on, match:class ^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$"
      "size 70% 70%, match:class ^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$"
      "center on, match:class ^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$"
      "opacity 0.8 0.7, match:class ^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$"
      "float on, match:class ^(nm-connection-editor|blueman-manager)$"
      "opacity 0.8 0.7, match:class ^(nm-connection-editor|blueman-manager)$"
      "float on, match:class ^(qt5ct|qt6ct)$"
      "opacity 0.8 0.7, match:class ^(qt5ct|qt6ct)$"

      # Multimedia video - no blur, full opacity
      "no_blur on, match:class ^([Mm]pv|vlc)$"
      "opacity 1.0, match:class ^([Mm]pv|vlc)$"
      "opacity 0.94 0.86, match:class ^([Aa]udacious)$"

      # Email - opacity
      "opacity 0.94 0.86, match:class ^([Tt]hunderbird|org.gnome.Evolution)$"

      # Games - fullscreen and no blur
      "fullscreen on, match:class ^(steam_app_\\d+)$"
      "no_blur on, match:class ^(steam_app_\\d+)$"

      # Idle inhibit for fullscreen apps
      "idle_inhibit fullscreen, match:fullscreen true"

      # JetBrains popups - don't steal focus
      "no_initial_focus on, match:class ^(jetbrains-.*)$"
    ];

    # Layer rules (for overlays like notifications, rofi, etc.)
    layerrule = [
      "blur on, match:namespace rofi"
      "ignore_alpha 1, match:namespace rofi"
      "blur on, match:namespace notifications"
      "ignore_alpha 1, match:namespace notifications"
    ];
  };
}
