# Run-or-raise script for Hyprland with focus history cycling
{
  FTS,
  pkgs,
  lib,
  ...
}: {
  FTS.desktop._.environment._.hyprland._.scripts._.run-or-raise = {
    description = "Run-or-raise script for Hyprland with focus history cycling";

    homeManager = {pkgs, ...}: {
      home.packages = [
        (pkgs.writeShellScriptBin "run-or-raise" ''
          #!/usr/bin/env bash
          # run-or-raise - Smart application launcher/focuser for Hyprland
          # Usage: run-or-raise <command> [args...]
          # Example: run-or-raise brave
          #          run-or-raise kitty
          #          run-or-raise nautilus

          set -euo pipefail

          APP_NAME="$1"
          shift || true
          EXTRA_ARGS="$@"

          # Map application names to their window classes and executable commands
          case "$APP_NAME" in
            brave)
              CLASS="brave-browser"
              COMMAND="${pkgs.brave}/bin/brave $EXTRA_ARGS"
              ;;
            librewolf)
              CLASS="LibreWolf"
              COMMAND="${pkgs.librewolf}/bin/librewolf $EXTRA_ARGS"
              ;;
            firefox)
              CLASS="firefox"
              COMMAND="${pkgs.firefox}/bin/firefox $EXTRA_ARGS"
              ;;
            kitty)
              CLASS="kitty"
              COMMAND="${pkgs.kitty}/bin/kitty $EXTRA_ARGS"
              ;;
            ghostty)
              CLASS="com.mitchellh.ghostty"
              COMMAND="${pkgs.ghostty}/bin/ghostty $EXTRA_ARGS"
              ;;
            obsidian)
              CLASS="obsidian"
              COMMAND="${pkgs.obsidian}/bin/obsidian $EXTRA_ARGS"
              ;;
            nautilus)
              CLASS="org.gnome.Nautilus"
              COMMAND="${pkgs.nautilus}/bin/nautilus $EXTRA_ARGS"
              ;;
            WebApp-youtube)
              CLASS="WebApp-youtube"
              COMMAND="gtk-launch youtube.desktop"
              ;;
            WebApp-chatgpt)
              CLASS="WebApp-chatgpt"
              COMMAND="gtk-launch chatgpt.desktop"
              ;;
            WebApp-gmail)
              CLASS="WebApp-gmail"
              COMMAND="gtk-launch gmail.desktop"
              ;;
            *)
              # Default: use app name as both class and command
              CLASS="$APP_NAME"
              COMMAND="$APP_NAME $EXTRA_ARGS"
              ;;
          esac

          # Get current active window class
          ACTIVE_CLASS=$(${pkgs.hyprland}/bin/hyprctl activewindow -j | ${pkgs.jq}/bin/jq -r '.class')

          # Get all windows matching our target class, sorted by focus history (most recent first)
          WINDOWS=$(${pkgs.hyprland}/bin/hyprctl clients -j | ${pkgs.jq}/bin/jq -r "
            [.[] | select(.class == \"$CLASS\")] | 
            sort_by(.focusHistoryID) | 
            .[] | .address
          ")

          # Count matching windows (check if empty string)
          if [ -z "$WINDOWS" ]; then
            WINDOW_COUNT=0
          else
            WINDOW_COUNT=$(echo "$WINDOWS" | ${pkgs.coreutils}/bin/wc -l)
          fi

          if [ "$WINDOW_COUNT" -eq 0 ]; then
              # No instances exist - launch new one
              ${pkgs.hyprland}/bin/hyprctl dispatch exec "$COMMAND"
              
          elif [ "$ACTIVE_CLASS" != "$CLASS" ]; then
              # Target app exists but not focused - focus most recent instance
              MOST_RECENT=$(echo "$WINDOWS" | ${pkgs.coreutils}/bin/head -n 1)
              ${pkgs.hyprland}/bin/hyprctl dispatch focuswindow "address:$MOST_RECENT"
              
          else
              # Target app is focused - cycle to next instance
              if [ "$WINDOW_COUNT" -eq 1 ]; then
                  # Only one instance, do nothing (already focused)
                  exit 0
              fi
              
              # Get current window address
              CURRENT_ADDR=$(${pkgs.hyprland}/bin/hyprctl activewindow -j | ${pkgs.jq}/bin/jq -r '.address')
              
              # Find current window in list and get next one
              NEXT_WINDOW=$(echo "$WINDOWS" | ${pkgs.gnugrep}/bin/grep -A 1 "$CURRENT_ADDR" | ${pkgs.coreutils}/bin/tail -n 1)
              
              # If we're at the end of the list, wrap to beginning
              if [ "$NEXT_WINDOW" == "$CURRENT_ADDR" ] || [ -z "$NEXT_WINDOW" ]; then
                  NEXT_WINDOW=$(echo "$WINDOWS" | ${pkgs.coreutils}/bin/head -n 1)
              fi
              
              ${pkgs.hyprland}/bin/hyprctl dispatch focuswindow "address:$NEXT_WINDOW"
          fi
        '')
      ];
    };
  };
}
