# Walker - Wayland-native application launcher
# A fast, extensible launcher for Wayland
{
  FTS,
  inputs,
  pkgs,
  ...
}: {
  # Flake inputs for Walker and Elephant
  flake-file.inputs = {
    elephant.url = "github:abenz1267/elephant";
    walker = {
      url = "github:abenz1267/walker";
      inputs.elephant.follows = "elephant";
    };
  };

  FTS.desktop._.environment._.hyprland._.apps._.walker = {
    description = ''
      Walker - Wayland-native application launcher.

      A fast, extensible launcher for Wayland with:
      - Application launcher
      - Window switcher
      - File search
      - Calculator
      - Custom plugins

      Homepage: https://github.com/abenz1267/walker
      Backend: https://github.com/abenz1267/elephant
    '';

    homeManager = {
      config,
      pkgs,
      ...
    }: {
      # Import Walker Home Manager module
      imports = [
        inputs.walker.homeManagerModules.default
      ];

      # Configure Walker
      programs.walker = {
        enable = true;
        runAsService = true;

        # Walker configuration
        config = {
          # General settings
          placeholder = "Search...";
          fullscreen = false;

          # UI settings
          list = {
            height = 200;
            always_show = true;
            hide_sub = false;
          };

          # Modules/Providers configuration
          modules = [
            {
              name = "applications";
              prefix = "";
            }
            {
              name = "runner";
              prefix = ">";
            }
            {
              name = "switcher";
              prefix = "/";
            }
            {
              name = "websearch";
              prefix = "?";
            }
            {
              name = "finder";
              prefix = "~";
            }
          ];

          # Search settings
          search = {
            delay = 0;
            placeholder = "Type to search...";
          };

          # Appearance
          ui = {
            anchors = {
              top = false;
              bottom = false;
              left = false;
              right = false;
            };
            window_background_color = "#1e1e2e";
            input_background_color = "#313244";
            text_color = "#cdd6f4";
            selection_background_color = "#45475a";
          };
        };
      };

      # Configure Elephant with workflow menu
      programs.elephant = {
        enable = true;
        installService = true;

        # Configure the menus provider with Lua
        provider.menus.lua = {
          workflows = ''
            Name = "workflows"
            NamePretty = "Hyprland Workflows"
            Icon = "preferences-desktop"
            Action = "${pkgs.writeShellScript "hyprland-workflow-switcher" ''
              #!/usr/bin/env bash
              profile_name="$1"
              profiles_dir="$HOME/.config/hypr/profiles"

              if [ ! -f "$profiles_dir/$profile_name.conf" ]; then
                notify-send -i "preferences-desktop-display" "Error" "Profile $profile_name does not exist"
                exit 1
              fi

              ln -sf "$profiles_dir/$profile_name.conf" "$HOME/.config/hypr/profile.conf"
              notify-send -i "preferences-desktop-display" "Workflow Switched" "Switched to $profile_name"
            ''} %VALUE%"
            Description = "Switch between Hyprland workflow profiles"
            SearchName = true
            Cache = true

            function GetEntries()
                local entries = {}
                local profiles_dir = os.getenv("HOME") .. "/.config/hypr/profiles"

                -- Get current profile
                local current_profile = "default"
                local profile_link = os.getenv("HOME") .. "/.config/hypr/profile.conf"
                local handle = io.popen("readlink '" .. profile_link .. "' 2>/dev/null")
                if handle then
                    local link_target = handle:read("*a"):gsub("\n", "")
                    handle:close()
                    current_profile = link_target:match("([^/]+)%.conf$") or "default"
                end

                -- Find all profile files
                local find_cmd = "find '" .. profiles_dir .. "' -maxdepth 1 -type f -name '*.conf' 2>/dev/null"
                handle = io.popen(find_cmd)
                if handle then
                    for line in handle:lines() do
                        local filename = line:match("([^/]+)$")
                        local profile_name = filename:match("(.+)%.conf$")
                        if profile_name then
                            local is_current = (profile_name == current_profile)
                            table.insert(entries, {
                                Text = profile_name,
                                Subtext = is_current and "Current" or "Hyprland workflow",
                                Value = profile_name,
                                Icon = is_current and "emblem-default" or "preferences-desktop",
                            })
                        end
                    end
                    handle:close()
                end

                return entries
            end
          '';
        };
      };
    };
  };
}
