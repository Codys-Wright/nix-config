# Hyprland Manager - Runtime appearance customization
# Two-tier menu system for managing animations, shaders, and more
{
  FTS,
  pkgs,
  ...
}: {
  FTS.desktop._.environment._.hyprland._.scripts._.hyprland-manager = {
    description = "Hyprland manager for runtime appearance customization";

    homeManager = {pkgs, ...}: {
      home.packages = [
        (pkgs.writeShellScriptBin "hyprland-manager" ''
          #!/usr/bin/env bash
          # Hyprland Manager - Appearance Customization
          
          confDir="''${XDG_CONFIG_HOME:-$HOME/.config}"
          hyprConfDir="$confDir/hypr"
          presets_dir="$hyprConfDir/presets"
          runtime_anim_path="$hyprConfDir/runtime-animation.conf"
          runtime_shader_path="$hyprConfDir/runtime-shader.conf"
          runtime_decor_path="$hyprConfDir/runtime-decoration.conf"
          runtime_layout_path="$hyprConfDir/runtime-layout.conf"
          runtime_cursor_path="$hyprConfDir/runtime-cursor.conf"
          runtime_wrules_path="$hyprConfDir/runtime-window-rules.conf"
          runtime_wsrules_path="$hyprConfDir/runtime-workspace-rules.conf"
          profile_conf_path="$hyprConfDir/profile.conf"
          
          # Get a Hyprland variable from a config file
          get_hypr_variable() {
            local var_name="$1"
            local config_file="$2"
          
            # Search for the variable definition ($<name> = <value>)
            local value
            value=$(${pkgs.gnugrep}/bin/grep "^\$''${var_name}\s*=" "$config_file" | ${pkgs.gnused}/bin/sed 's/^[^=]*= *//; s/#.*$//; s/ *$//')
          
            if [[ -n "$value" ]]; then
              echo "$value"
            else
              return 1
            fi
          }
          
          # Main menu
          fn_main_menu() {
            local options=(
              "Animations"
              "Shaders"
              "Decorations"
              "Layouts"
              "Cursor"
              "Window Rules"
              "Workspace Rules"
              "Reset to Workflow Defaults"
            )
            
            local selection
            selection=$(${pkgs.coreutils}/bin/printf "%s\n" "''${options[@]}" | ${pkgs.walker}/bin/walker --dmenu --placeholder "Hyprland Manager:")
            
            case "$selection" in
              "Animations")
                fn_animations_menu
                ;;
              "Shaders")
                fn_shaders_menu
                ;;
              "Decorations")
                fn_decorations_menu
                ;;
              "Layouts")
                fn_layouts_menu
                ;;
              "Cursor")
                fn_cursor_menu
                ;;
              "Window Rules")
                fn_window_rules_menu
                ;;
              "Workspace Rules")
                fn_workspace_rules_menu
                ;;
              "Reset to Workflow Defaults")
                fn_reset
                ;;
            esac
          }
          
          # Animations submenu
          fn_animations_menu() {
            local animations_dir="$presets_dir/animations"
            
            if [ ! -d "$animations_dir" ]; then
              ${pkgs.libnotify}/bin/notify-send -i "preferences-desktop-display" "Error" "Animations directory not found"
              exit 1
            fi
            
            # Discover all animation presets (dynamically)
            # Use -L to follow symlinks (home-manager creates symlinks)
            local animations=()
            while IFS= read -r conf_file; do
              local anim_name
              anim_name=$(${pkgs.coreutils}/bin/basename "$conf_file" .conf)
              animations+=("$anim_name")
            done < <(${pkgs.findutils}/bin/find -L "$animations_dir" -type f -name "*.conf" | ${pkgs.coreutils}/bin/sort)
            
            if [ ''${#animations[@]} -eq 0 ]; then
              ${pkgs.libnotify}/bin/notify-send -i "preferences-desktop-display" "Error" "No animation presets found"
              exit 1
            fi
            
            # Show menu and get selection
            local selection
            selection=$(${pkgs.coreutils}/bin/printf "%s\n" "''${animations[@]}" | ${pkgs.walker}/bin/walker --dmenu --placeholder "Select Animation Preset:")
            
            # Apply selection
            if [[ -n "$selection" ]]; then
              echo "source = ./presets/animations/''${selection}.conf" > "$runtime_anim_path"
              hyprctl reload
              ${pkgs.libnotify}/bin/notify-send -i "preferences-desktop-display" "Animation Changed" "Applied: $selection"
            fi
          }
          
          # Shaders submenu
          fn_shaders_menu() {
            local shaders_dir="$presets_dir/shaders"
            
            if [ ! -d "$shaders_dir" ]; then
              ${pkgs.libnotify}/bin/notify-send -i "preferences-desktop-display" "Error" "Shaders directory not found"
              exit 1
            fi
            
            # Discover all shader presets (dynamically)
            # Use -L to follow symlinks (home-manager creates symlinks)
            local shaders=("None (Disable Shader)")
            while IFS= read -r frag_file; do
              local shader_name
              shader_name=$(${pkgs.coreutils}/bin/basename "$frag_file")
              shaders+=("$shader_name")
            done < <(${pkgs.findutils}/bin/find -L "$shaders_dir" -type f -name "*.frag" | ${pkgs.coreutils}/bin/sort)
            
            # Show menu and get selection
            local selection
            selection=$(${pkgs.coreutils}/bin/printf "%s\n" "''${shaders[@]}" | ${pkgs.walker}/bin/walker --dmenu --placeholder "Select Shader Effect:")
            
            # Apply selection
            if [[ -n "$selection" ]]; then
              if [[ "$selection" == "None (Disable Shader)" ]]; then
                # Clear shader
                ${pkgs.coreutils}/bin/rm -f "$runtime_shader_path"
                ${pkgs.coreutils}/bin/touch "$runtime_shader_path"
                ${pkgs.libnotify}/bin/notify-send -i "preferences-desktop-display" "Shader Disabled" "Screen shader removed"
              else
                # Apply shader using decoration:screen_shader syntax for proper merging
                echo "decoration:screen_shader = ./presets/shaders/''${selection}" > "$runtime_shader_path"
                ${pkgs.libnotify}/bin/notify-send -i "preferences-desktop-display" "Shader Changed" "Applied: $selection"
              fi
              hyprctl reload
            fi
          }
          
          # Decorations submenu
          fn_decorations_menu() {
            local decorations_dir="$presets_dir/decorations"
            
            if [ ! -d "$decorations_dir" ]; then
              ${pkgs.libnotify}/bin/notify-send -i "preferences-desktop-display" "Error" "Decorations directory not found"
              exit 1
            fi
            
            # Discover all decoration presets (dynamically)
            local decorations=()
            while IFS= read -r conf_file; do
              local decor_name
              decor_name=$(${pkgs.coreutils}/bin/basename "$conf_file" .conf)
              decorations+=("$decor_name")
            done < <(${pkgs.findutils}/bin/find -L "$decorations_dir" -type f -name "*.conf" | ${pkgs.coreutils}/bin/sort)
            
            if [ ''${#decorations[@]} -eq 0 ]; then
              ${pkgs.libnotify}/bin/notify-send -i "preferences-desktop-display" "Error" "No decoration presets found"
              exit 1
            fi
            
            # Show menu and get selection
            local selection
            selection=$(${pkgs.coreutils}/bin/printf "%s\n" "''${decorations[@]}" | ${pkgs.walker}/bin/walker --dmenu --placeholder "Select Decoration Style:")
            
            # Apply selection
            if [[ -n "$selection" ]]; then
              # Save to runtime file for persistence
              echo "source = ./presets/decorations/''${selection}.conf" > "$runtime_decor_path"
              
              # Apply settings dynamically using hyprctl keyword
              local preset_file="$decorations_dir/''${selection}.conf"
              
              # Parse Hyprland config format: section { key=value }
              local current_section=""
              while IFS= read -r line; do
                # Skip comments and empty lines
                [[ "$line" =~ ^[[:space:]]*# ]] && continue
                [[ -z "$line" ]] && continue
                
                # Check if this is a section header (e.g., "decoration {" or "general {")
                if [[ "$line" =~ ^[[:space:]]*([a-zA-Z_]+)[[:space:]]*\{[[:space:]]*$ ]]; then
                  current_section="''${BASH_REMATCH[1]}"
                  continue
                fi
                
                # Check if this is closing brace
                if [[ "$line" =~ ^[[:space:]]*\}[[:space:]]*$ ]]; then
                  current_section=""
                  continue
                fi
                
                # Parse key=value pairs
                if [[ "$line" =~ ^[[:space:]]*([a-zA-Z_]+)[[:space:]]*=[[:space:]]*(.+)[[:space:]]*$ ]]; then
                  local key="''${BASH_REMATCH[1]}"
                  local value="''${BASH_REMATCH[2]}"
                  
                  # Build full key path (section:key)
                  if [[ -n "$current_section" ]]; then
                    local full_key="''${current_section}:''${key}"
                  else
                    local full_key="''${key}"
                  fi
                  
                  # Apply the setting
                  hyprctl keyword "$full_key" "$value" 2>/dev/null || true
                fi
              done < "$preset_file"
              
              ${pkgs.libnotify}/bin/notify-send -i "preferences-desktop-display" "Decoration Changed" "Applied: $selection"
            fi
          }
          
          # Layouts submenu
          fn_layouts_menu() {
            local layouts_dir="$presets_dir/layouts"
            
            if [ ! -d "$layouts_dir" ]; then
              ${pkgs.libnotify}/bin/notify-send -i "preferences-desktop-display" "Error" "Layouts directory not found"
              exit 1
            fi
            
            # Discover all layout presets (dynamically)
            local layouts=()
            while IFS= read -r conf_file; do
              local layout_name
              layout_name=$(${pkgs.coreutils}/bin/basename "$conf_file" .conf)
              layouts+=("$layout_name")
            done < <(${pkgs.findutils}/bin/find -L "$layouts_dir" -type f -name "*.conf" | ${pkgs.coreutils}/bin/sort)
            
            if [ ''${#layouts[@]} -eq 0 ]; then
              ${pkgs.libnotify}/bin/notify-send -i "preferences-desktop-display" "Error" "No layout presets found"
              exit 1
            fi
            
            # Show menu and get selection
            local selection
            selection=$(${pkgs.coreutils}/bin/printf "%s\n" "''${layouts[@]}" | ${pkgs.walker}/bin/walker --dmenu --placeholder "Select Window Layout:")
            
            # Apply selection
            if [[ -n "$selection" ]]; then
              # Save to runtime file for persistence
              echo "source = ./presets/layouts/''${selection}.conf" > "$runtime_layout_path"
              
              # Apply settings dynamically using hyprctl keyword
              local preset_file="$layouts_dir/''${selection}.conf"
              
              # Parse Hyprland config format: section { key=value }
              local current_section=""
              while IFS= read -r line; do
                # Skip comments and empty lines
                [[ "$line" =~ ^[[:space:]]*# ]] && continue
                [[ -z "$line" ]] && continue
                
                # Check if this is a section header (e.g., "dwindle {" or "general {")
                if [[ "$line" =~ ^[[:space:]]*([a-zA-Z_]+)[[:space:]]*\{[[:space:]]*$ ]]; then
                  current_section="''${BASH_REMATCH[1]}"
                  continue
                fi
                
                # Check if this is closing brace
                if [[ "$line" =~ ^[[:space:]]*\}[[:space:]]*$ ]]; then
                  current_section=""
                  continue
                fi
                
                # Parse key=value pairs
                if [[ "$line" =~ ^[[:space:]]*([a-zA-Z_]+)[[:space:]]*=[[:space:]]*(.+)[[:space:]]*$ ]]; then
                  local key="''${BASH_REMATCH[1]}"
                  local value="''${BASH_REMATCH[2]}"
                  
                  # Build full key path (section:key)
                  if [[ -n "$current_section" ]]; then
                    local full_key="''${current_section}:''${key}"
                  else
                    local full_key="''${key}"
                  fi
                  
                  # Apply the setting
                  hyprctl keyword "$full_key" "$value" 2>/dev/null || true
                fi
              done < "$preset_file"
              
              # Reload to ensure everything is applied
              hyprctl reload
              ${pkgs.libnotify}/bin/notify-send -i "preferences-desktop-display" "Layout Changed" "Applied: $selection"
            fi
          }
          
          # Cursor submenu
          fn_cursor_menu() {
            local cursor_dir="$presets_dir/cursor"
            
            if [ ! -d "$cursor_dir" ]; then
              ${pkgs.libnotify}/bin/notify-send -i "preferences-desktop-display" "Error" "Cursor directory not found"
              exit 1
            fi
            
            # Discover all cursor presets (dynamically)
            local cursors=()
            while IFS= read -r conf_file; do
              local cursor_name
              cursor_name=$(${pkgs.coreutils}/bin/basename "$conf_file" .conf)
              cursors+=("$cursor_name")
            done < <(${pkgs.findutils}/bin/find -L "$cursor_dir" -type f -name "*.conf" | ${pkgs.coreutils}/bin/sort)
            
            if [ ''${#cursors[@]} -eq 0 ]; then
              ${pkgs.libnotify}/bin/notify-send -i "preferences-desktop-display" "Error" "No cursor presets found"
              exit 1
            fi
            
            # Show menu and get selection
            local selection
            selection=$(${pkgs.coreutils}/bin/printf "%s\n" "''${cursors[@]}" | ${pkgs.walker}/bin/walker --dmenu --placeholder "Select Cursor Behavior:")
            
            # Apply selection
            if [[ -n "$selection" ]]; then
              # Save to runtime file for persistence
              echo "source = ./presets/cursor/''${selection}.conf" > "$runtime_cursor_path"
              
              # Apply settings dynamically using hyprctl keyword
              local preset_file="$cursor_dir/''${selection}.conf"
              
              # Parse Hyprland config format: section { key=value }
              local current_section=""
              while IFS= read -r line; do
                # Skip comments and empty lines
                [[ "$line" =~ ^[[:space:]]*# ]] && continue
                [[ -z "$line" ]] && continue
                
                # Check if this is a section header (e.g., "cursor {")
                if [[ "$line" =~ ^[[:space:]]*([a-zA-Z_]+)[[:space:]]*\{[[:space:]]*$ ]]; then
                  current_section="''${BASH_REMATCH[1]}"
                  continue
                fi
                
                # Check if this is closing brace
                if [[ "$line" =~ ^[[:space:]]*\}[[:space:]]*$ ]]; then
                  current_section=""
                  continue
                fi
                
                # Parse key=value pairs
                if [[ "$line" =~ ^[[:space:]]*([a-zA-Z_]+)[[:space:]]*=[[:space:]]*(.+)[[:space:]]*$ ]]; then
                  local key="''${BASH_REMATCH[1]}"
                  local value="''${BASH_REMATCH[2]}"
                  
                  # Build full key path (section:key)
                  if [[ -n "$current_section" ]]; then
                    local full_key="''${current_section}:''${key}"
                  else
                    local full_key="''${key}"
                  fi
                  
                  # Apply the setting
                  hyprctl keyword "$full_key" "$value" 2>/dev/null || true
                fi
              done < "$preset_file"
              
              ${pkgs.libnotify}/bin/notify-send -i "preferences-desktop-display" "Cursor Changed" "Applied: $selection"
            fi
          }
          
          # Window Rules submenu
          fn_window_rules_menu() {
            local wrules_dir="$presets_dir/window-rules"
            
            if [ ! -d "$wrules_dir" ]; then
              ${pkgs.libnotify}/bin/notify-send -i "preferences-desktop-display" "Error" "Window rules directory not found"
              exit 1
            fi
            
            # Discover all window-rules presets (dynamically)
            local wrules=()
            while IFS= read -r conf_file; do
              local wrule_name
              wrule_name=$(${pkgs.coreutils}/bin/basename "$conf_file" .conf)
              wrules+=("$wrule_name")
            done < <(${pkgs.findutils}/bin/find -L "$wrules_dir" -type f -name "*.conf" | ${pkgs.coreutils}/bin/sort)
            
            if [ ''${#wrules[@]} -eq 0 ]; then
              ${pkgs.libnotify}/bin/notify-send -i "preferences-desktop-display" "Error" "No window rules presets found"
              exit 1
            fi
            
            # Show menu and get selection
            local selection
            selection=$(${pkgs.coreutils}/bin/printf "%s\n" "''${wrules[@]}" | ${pkgs.walker}/bin/walker --dmenu --placeholder "Select Window Rules:")
            
            # Apply selection
            if [[ -n "$selection" ]]; then
              echo "source = ./presets/window-rules/''${selection}.conf" > "$runtime_wrules_path"
              hyprctl reload
              ${pkgs.libnotify}/bin/notify-send -i "preferences-desktop-display" "Window Rules Changed" "Applied: $selection"
            fi
          }
          
          # Workspace Rules submenu
          fn_workspace_rules_menu() {
            local wsrules_dir="$presets_dir/workspace-rules"
            
            if [ ! -d "$wsrules_dir" ]; then
              ${pkgs.libnotify}/bin/notify-send -i "preferences-desktop-display" "Error" "Workspace rules directory not found"
              exit 1
            fi
            
            # Discover all workspace-rules presets (dynamically)
            local wsrules=()
            while IFS= read -r conf_file; do
              local wsrule_name
              wsrule_name=$(${pkgs.coreutils}/bin/basename "$conf_file" .conf)
              wsrules+=("$wsrule_name")
            done < <(${pkgs.findutils}/bin/find -L "$wsrules_dir" -type f -name "*.conf" | ${pkgs.coreutils}/bin/sort)
            
            if [ ''${#wsrules[@]} -eq 0 ]; then
              ${pkgs.libnotify}/bin/notify-send -i "preferences-desktop-display" "Error" "No workspace rules presets found"
              exit 1
            fi
            
            # Show menu and get selection
            local selection
            selection=$(${pkgs.coreutils}/bin/printf "%s\n" "''${wsrules[@]}" | ${pkgs.walker}/bin/walker --dmenu --placeholder "Select Workspace Rules:")
            
            # Apply selection
            if [[ -n "$selection" ]]; then
              echo "source = ./presets/workspace-rules/''${selection}.conf" > "$runtime_wsrules_path"
              hyprctl reload
              ${pkgs.libnotify}/bin/notify-send -i "preferences-desktop-display" "Workspace Rules Changed" "Applied: $selection"
            fi
          }
          
          # Reset to workflow defaults
          fn_reset() {
            # Get current workflow name
            local current_workflow
            current_workflow=$(get_hypr_variable "PROFILE_NAME" "$profile_conf_path")
            
            if [[ -z "$current_workflow" ]]; then
              ${pkgs.libnotify}/bin/notify-send -i "preferences-desktop-display" "Error" "Could not determine current workflow"
              exit 1
            fi
            
            # Re-apply current workflow (which will reset overrides to workflow defaults)
            hyprland-workflow-switcher --set "$current_workflow"
            
            ${pkgs.libnotify}/bin/notify-send -i "preferences-desktop-display" "Reset Complete" "Restored defaults for: $current_workflow"
          }
          
          # Show help
          fn_help() {
            cat <<HELP
          Usage: $0 [OPTIONS]
          
          Hyprland Manager - Runtime appearance customization
          
          Options:
              --animations    | -a       Open animations menu directly
              --shaders       | -s       Open shaders menu directly
              --decorations   | -d       Open decorations menu directly
              --layouts       | -l       Open layouts menu directly
              --cursor        | -c       Open cursor menu directly
              --window-rules  | -w       Open window rules menu directly
              --workspace-rules | -W     Open workspace rules menu directly
              --reset         | -r       Reset to workflow defaults
              --help          | -h       Show this help message
          
          Without options: Opens main menu
          
          Examples:
              hyprland-manager                     # Open main menu
              hyprland-manager --animations        # Direct to animations
              hyprland-manager --decorations       # Direct to decorations
              hyprland-manager --layouts           # Direct to layouts
              hyprland-manager --reset             # Reset to defaults
          HELP
          }
          
          # Validation checks
          if [ ! -d "$presets_dir" ]; then
            ${pkgs.libnotify}/bin/notify-send -i "preferences-desktop-display" "Error" "Presets directory does not exist"
            exit 1
          fi
          
          # Parse command line arguments
          if [ $# -eq 0 ]; then
            # No arguments - show main menu
            fn_main_menu
          else
            case "$1" in
              -a|--animations)
                fn_animations_menu
                ;;
              -s|--shaders)
                fn_shaders_menu
                ;;
              -d|--decorations)
                fn_decorations_menu
                ;;
              -l|--layouts)
                fn_layouts_menu
                ;;
              -c|--cursor)
                fn_cursor_menu
                ;;
              -w|--window-rules)
                fn_window_rules_menu
                ;;
              -W|--workspace-rules)
                fn_workspace_rules_menu
                ;;
              -r|--reset)
                fn_reset
                ;;
              -h|--help)
                fn_help
                ;;
              *)
                echo "Unknown option: $1"
                fn_help
                exit 1
                ;;
            esac
          fi
        '')
      ];
    };
  };
}
