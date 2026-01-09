# Default Window Rules - Comprehensive base rules
# Using windowrulev2 syntax for Hyprland v0.52.2
{
  name = "default";
  settings = {
    # Picture-in-Picture - universal floating video
    windowrulev2 = [
      "float, title:^(Picture-in-Picture)$"
      "pin, title:^(Picture-in-Picture)$"
      "size 640 360, title:^(Picture-in-Picture)$"
      "move 72% 7%, title:^(Picture-in-Picture)$"
      "keepaspectratio, title:^(Picture-in-Picture)$"
      "opacity 0.95 0.75, title:^(Picture-in-Picture)$"
      
      # File dialogs - float and center
      "float, title:^(Open File)$"
      "float, title:^(Save File)$"
      "float, title:^(Save As)$"
      "size 70% 60%, title:^(Save As)$"
      "center, title:^(Save As)$"
      "float, initialTitle:^(Open Files)$"
      "size 70% 60%, initialTitle:^(Open Files)$"
      
      # Authentication dialogs
      "float, title:^(Authentication Required)$"
      "center, title:^(Authentication Required)$"
      
      # Calculator
      "float, class:^(org.gnome.Calculator)$"
      "float, class:^([Qq]alculate-gtk)$"
      
      # Browsers - opacity
      "opacity 0.99 0.8, class:^([Ff]irefox|org.mozilla.firefox|[Ff]irefox-esr)$"
      "opacity 0.99 0.8, class:^([Gg]oogle-chrome(-beta|-dev|-unstable)?)$"
      "opacity 0.99 0.8, class:^([Cc]hromium)$"
      "opacity 0.99 0.8, class:^([Mm]icrosoft-edge(-stable|-beta|-dev)?)$"
      "opacity 0.99 0.8, class:^(Brave-browser(-beta|-dev)?)$"
      "opacity 0.99 0.8, class:^(zen-alpha|zen)$"
      
      # Terminals - opacity
      "opacity 0.9 0.7, class:^(Alacritty|kitty|kitty-dropterm)$"
      
      # Communication - opacity
      "opacity 0.94 0.86, class:^([Dd]iscord|[Ww]ebCord|[Vv]esktop)$"
      "opacity 0.94 0.86, class:^([Ff]erdium)$"
      "opacity 0.94 0.86, class:^([Ww]hatsapp-for-linux)$"
      "opacity 0.94 0.86, class:^(org.telegram.desktop|io.github.tdesktop_x64.TDesktop)$"
      "opacity 0.94 0.86, class:^(Element)$"
      
      # Development - opacity
      "opacity 0.9 0.8, class:^(codium|codium-url-handler|VSCodium)$"
      "opacity 0.9 0.8, class:^(VSCode|code|code-url-handler)$"
      "opacity 0.9 0.8, class:^(jetbrains-.+)$"
      
      # File managers - opacity
      "opacity 0.9 0.8, class:^([Tt]hunar|org.gnome.Nautilus|[Pp]cmanfm-qt)$"
      
      # Settings/utilities - float and opacity
      "float, class:^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$"
      "size 70% 70%, class:^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$"
      "center, class:^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$"
      "opacity 0.8 0.7, class:^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$"
      "float, class:^(nm-connection-editor|blueman-manager)$"
      "opacity 0.8 0.7, class:^(nm-connection-editor|blueman-manager)$"
      "float, class:^(qt5ct|qt6ct)$"
      "opacity 0.8 0.7, class:^(qt5ct|qt6ct)$"
      
      # Multimedia video - no blur, full opacity
      "noblur, class:^([Mm]pv|vlc)$"
      "opacity 1.0, class:^([Mm]pv|vlc)$"
      "opacity 0.94 0.86, class:^([Aa]udacious)$"
      
      # Email - opacity
      "opacity 0.94 0.86, class:^([Tt]hunderbird|org.gnome.Evolution)$"
      
      # Games - fullscreen and no blur
      "fullscreen, class:^(steam_app_\\d+)$"
      "noblur, class:^(steam_app_\\d+)$"
      
      # Idle inhibit for fullscreen apps
      "idleinhibit fullscreen, fullscreen:1"
      
      # JetBrains popups - don't steal focus
      "noinitialfocus, class:^(jetbrains-.*)"
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
