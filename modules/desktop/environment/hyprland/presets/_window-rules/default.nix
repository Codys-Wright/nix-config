# Default Window Rules - Comprehensive base rules
{
  name = "default";
  settings = {
    # Picture-in-Picture - universal floating video
    windowrule = [
      "title:^(Picture-in-Picture)$, float"
      "title:^(Picture-in-Picture)$, pin"
      "title:^(Picture-in-Picture)$, size 640 360"
      "title:^(Picture-in-Picture)$, move 72% 7%"
      "title:^(Picture-in-Picture)$, keepaspectratio"
      "title:^(Picture-in-Picture)$, opacity 0.95 0.75"

      # File dialogs - float and center
      "title:^(Open File)$, float"
      "title:^(Save File)$, float"
      "title:^(Save As)$, float"
      "title:^(Save As)$, size 70% 60%"
      "title:^(Save As)$, center"
      "initialTitle:^(Open Files)$, float"
      "initialTitle:^(Open Files)$, size 70% 60%"

      # Authentication dialogs
      "title:^(Authentication Required)$, float"
      "title:^(Authentication Required)$, center"

      # Calculator
      "class:^(org.gnome.Calculator)$, float"
      "class:^([Qq]alculate-gtk)$, float"

      # Browsers - opacity
      "class:^([Ff]irefox|org.mozilla.firefox|[Ff]irefox-esr)$, opacity 0.99 0.8"
      "class:^([Gg]oogle-chrome(-beta|-dev|-unstable)?)$, opacity 0.99 0.8"
      "class:^([Cc]hromium)$, opacity 0.99 0.8"
      "class:^([Mm]icrosoft-edge(-stable|-beta|-dev)?)$, opacity 0.99 0.8"
      "class:^(Brave-browser(-beta|-dev)?)$, opacity 0.99 0.8"
      "class:^(zen-alpha|zen)$, opacity 0.99 0.8"

      # Terminals - opacity
      "class:^(Alacritty|kitty|kitty-dropterm)$, opacity 0.9 0.7"

      # Communication - opacity
      "class:^([Dd]iscord|[Ww]ebCord|[Vv]esktop)$, opacity 0.94 0.86"
      "class:^([Ff]erdium)$, opacity 0.94 0.86"
      "class:^([Ww]hatsapp-for-linux)$, opacity 0.94 0.86"
      "class:^(org.telegram.desktop|io.github.tdesktop_x64.TDesktop)$, opacity 0.94 0.86"
      "class:^(Element)$, opacity 0.94 0.86"

      # Development - opacity
      "class:^(codium|codium-url-handler|VSCodium)$, opacity 0.9 0.8"
      "class:^(VSCode|code|code-url-handler)$, opacity 0.9 0.8"
      "class:^(jetbrains-.+)$, opacity 0.9 0.8"

      # File managers - opacity
      "class:^([Tt]hunar|org.gnome.Nautilus|[Pp]cmanfm-qt)$, opacity 0.9 0.8"

      # Settings/utilities - float and opacity
      "class:^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$, float"
      "class:^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$, size 70% 70%"
      "class:^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$, center"
      "class:^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$, opacity 0.8 0.7"
      "class:^(nm-connection-editor|blueman-manager)$, float"
      "class:^(nm-connection-editor|blueman-manager)$, opacity 0.8 0.7"
      "class:^(qt5ct|qt6ct)$, float"
      "class:^(qt5ct|qt6ct)$, opacity 0.8 0.7"

      # Multimedia video - no blur, full opacity
      "class:^([Mm]pv|vlc)$, noblur"
      "class:^([Mm]pv|vlc)$, opacity 1.0"
      "class:^([Aa]udacious)$, opacity 0.94 0.86"

      # Email - opacity
      "class:^([Tt]hunderbird|org.gnome.Evolution)$, opacity 0.94 0.86"

      # Games - fullscreen and no blur
      "class:^(steam_app_\\d+)$, fullscreen"
      "class:^(steam_app_\\d+)$, noblur"

      # Idle inhibit for fullscreen apps
      "fullscreen:1, idleinhibit fullscreen"

      # JetBrains popups - don't steal focus
      "class:^(jetbrains-.*)$, noinitialfocus"
    ];
    
    # Layer rules (for overlays like notifications, rofi, etc.)
    # Updated for Hyprland 0.53+ syntax
    layerrule = [
      "blur on, match:namespace rofi"
      "ignore_alpha 1, match:namespace rofi"
      "blur on, match:namespace notifications"
      "ignore_alpha 1, match:namespace notifications"
    ];
  };
}
