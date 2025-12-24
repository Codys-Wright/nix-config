# Hyprland workflow switcher script
# Based on: https://github.com/heraldofsolace/hyprland-profile-switcher
{
  FTS,
  pkgs,
  ...
}: {
  FTS.desktop._.environment._.hyprland._.scripts._.workflow-switcher = {
    description = "Hyprland workflow switcher script with walker integration";

    homeManager = {pkgs, ...}: {
      home.packages = [
        (pkgs.writeShellScriptBin "hyprland-workflow-switcher" ''
          #!/usr/bin/env bash
          # Hyprland Workflow Switcher
          # Based on hyprland-profile-switcher by heraldofsolace

          confDir="''${XDG_CONFIG_HOME:-$HOME/.config}"
          hyprConfDir="$confDir/hypr"
          profiles_dir="$hyprConfDir/profiles"
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
              echo "Variable '$var_name' not found." >&2
              return 1
            fi
          }

          # Set the active profile
          set_profile() {
            selected_profile="$1"
            ${pkgs.coreutils}/bin/ln -sf "$profiles_dir/''${selected_profile}.conf" "$hyprConfDir/profile.conf"
            ${pkgs.libnotify}/bin/notify-send -i "preferences-desktop-display" "Workflow Switched" "Switched to workflow: ''${selected_profile}"
          }

          # Interactive selection using a menu command
          fn_select() {
            command="$1"
            
            # Build profile list
            profile_list=("default")
            while IFS= read -r profile_path; do
              # Sanitize profile name
              profile_name=$(${pkgs.coreutils}/bin/basename "$profile_path" .conf | ${pkgs.findutils}/bin/xargs)
              [ "$profile_name" = "default" ] && continue
              profile_list+=("''${profile_name}")
            done < <(${pkgs.findutils}/bin/find -L "$profiles_dir" -type f -name "*.conf" 2>/dev/null)

            # Show menu and select
            selected_profile=$(${pkgs.coreutils}/bin/printf "%s\n" "''${profile_list[@]}" | ''${command})
            
            # Only set if something was selected
            if [[ -n "$selected_profile" ]]; then
              set_profile "$selected_profile"
            fi
          }

          # Get current workflow
          fn_get_current() {
            if [ ! -f "$hyprConfDir/profile.conf" ]; then
              printf "+++"
              return
            fi

            current_profile=$(get_hypr_variable "PROFILE_NAME" "''${hyprConfDir}/profile.conf")
            printf "%s\n" "$current_profile"
          }

          # Set specific workflow
          fn_set() {
            profile_name="$1"
            if [ ! -f "''${profiles_dir}/''${profile_name}.conf" ]; then
              ${pkgs.libnotify}/bin/notify-send -i "preferences-desktop-display" "Error" "''${profiles_dir}/''${profile_name}.conf does not exist"
              exit 1
            fi

            set_profile "''${profile_name}"
          }

          # Reset to default workflow
          fn_reset() {
            fn_set "default"
          }

          # Show help
          fn_help() {
            cat <<HELP
          Usage: $0 [OPTIONS]

          Options:
              --select <cmd>  | -s       Select workflow using menu command (e.g., walker, rofi)
              --set <name>    | -t       Set specific workflow
              --get-current   | -g       Get current workflow
              --reset         | -r       Reset to default workflow
              --help          | -h       Show this help message

          Examples:
              hyprland-workflow-switcher --select walker
              hyprland-workflow-switcher --set gaming
              hyprland-workflow-switcher --get-current
              hyprland-workflow-switcher --reset
          HELP
          }

          # Validation checks
          if [ ! -d "$profiles_dir" ]; then
            ${pkgs.libnotify}/bin/notify-send -i "preferences-desktop-display" "Error" "Profiles directory does not exist at $profiles_dir"
            exit 1
          fi

          if [ ! -f "$profiles_dir/default.conf" ]; then
            ${pkgs.libnotify}/bin/notify-send -i "preferences-desktop-display" "Error" "Default profile does not exist"
            exit 1
          fi

          # Initialize profile symlink if it doesn't exist
          if [ ! -f "$profile_conf_path" ]; then
            set_profile "default"
          fi

          # Parse command line arguments
          if ! VALID_ARGS=$(${pkgs.util-linux}/bin/getopt -o s:gt:rh --long select:,get-current,set:,reset,help -- "$@"); then
              exit 1
          fi

          eval set -- "$VALID_ARGS"
          while true; do
            case "$1" in
              -s|--select)
                  fn_select "''${2}"
                  shift 2
                  break
                  ;;
              -g|--get-current)
                  fn_get_current
                  shift
                  break
                  ;;
              -t|--set)
                  fn_set "$2"
                  shift 2
                  break
                  ;;
              -r|--reset)
                  fn_reset
                  shift
                  break
                  ;;
              -h|--help|--) 
                  fn_help
                  shift
                  break 
                  ;;
            esac
          done
        '')
      ];
    };
  };
}
