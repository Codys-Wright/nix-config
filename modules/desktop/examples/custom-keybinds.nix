# Example: Custom Keybind Configurations
# This shows how to customize the desktop keybind abstractions for specific needs
{ ... }:
{
  den.aspects.custom-keybinds = {
    description = "Example custom keybind configurations";

    homeManager = { config, pkgs, lib, ... }: {
      # Override default applications and their keybinds
      desktop.keybinds = {
        # Customize application preferences
        apps = {
          # Use Alacritty instead of Kitty for terminal
          terminal = {
            key = "RETURN";  # Keep the same key
            package = pkgs.alacritty;
            command = "${pkgs.alacritty}/bin/alacritty";
          };

          # Use Firefox instead of LibreWolf
          browser = {
            key = "B";  # Keep the same key
            package = pkgs.firefox;
            command = "${pkgs.firefox}/bin/firefox";
          };

          # Use Thunar instead of Nautilus for files
          files = {
            key = "E";  # Keep the same key
            package = pkgs.thunar;
            command = "${pkgs.thunar}/bin/thunar";
          };

          # Use Logseq instead of Obsidian for notes
          notes = {
            key = "N";  # Keep the same key
            package = pkgs.logseq;
            command = "${pkgs.logseq}/bin/logseq";
          };

          # Customize AI to use different service
          ai = {
            key = "A";  # Keep the same key
            package = null;
            command = "${config.desktop.keybinds.apps.browser.command} https://claude.ai";
          };

          # Use different music player
          music = {
            key = "M";  # Keep the same key
            package = pkgs.rhythmbox;
            command = "${pkgs.rhythmbox}/bin/rhythmbox";
          };

          # Add custom application not in defaults
          calculator = {
            key = "C";
            package = pkgs.gnome-calculator;
            command = "${pkgs.gnome-calculator}/bin/gnome-calculator";
          };

          # Add development-specific apps
          docker-ui = {
            key = "D";
            package = pkgs.lazydocker;
            command = "${config.desktop.keybinds.apps.terminal.command} -e ${pkgs.lazydocker}/bin/lazydocker";
          };

          # Git UI
          git-ui = {
            key = "G";
            package = pkgs.lazygit;
            command = "${config.desktop.keybinds.apps.terminal.command} -e ${pkgs.lazygit}/bin/lazygit";
          };
        };

        # Customize window management keys (for Vim users who want different layout)
        window = {
          # Use different keys for window focus (more Vim-like)
          focus-left.key = "H";
          focus-down.key = "J";
          focus-up.key = "K";
          focus-right.key = "L";

          # Add custom window actions
          maximize = {
            key = "F11";
            action = "toggle-maximize";
          };

          minimize = {
            key = "U";
            action = "minimize";
          };
        };

        # Override modifier preferences
        mod = "SUPER";        # Could change to ALT for different workflow
        shiftMod = "SUPER_SHIFT";
        altMod = "ALT";

        # Add custom system functions
        system = {
          # Keep existing ones but add new ones
          screenshot = {
            key = "S";
            command = "grimblast copy area";
          };

          clipboard = {
            key = "V";
            command = "cliphist list | rofi -dmenu | cliphist decode | wl-copy";
          };

          emoji = {
            key = "period";
            command = "rofi -show emoji";
          };

          brightness-up = {
            key = "F6";
            command = "brightnessctl set +10%";
          };

          brightness-down = {
            key = "F5";
            command = "brightnessctl set 10%-";
          };
        };
      };

      # Add additional packages for the custom apps
      home.packages = with pkgs; [
        # Custom apps
        alacritty
        firefox
        thunar
        logseq
        rhythmbox
        gnome-calculator
        lazydocker
        lazygit

        # System utilities for custom keybinds
        grimblast
        cliphist
        brightnessctl
      ];
    };
  };

  # Example of profile-specific keybinds
  den.aspects.developer-keybinds = {
    description = "Developer-focused keybind overrides";

    homeManager = { config, pkgs, lib, ... }: {
      desktop.keybinds.apps = {
        # Quick access to development tools
        ide = {
          key = "I";
          package = pkgs.vscode;
          command = "${pkgs.vscode}/bin/code";
        };

        database = {
          key = "shift+D";
          package = pkgs.dbeaver-bin;
          command = "${pkgs.dbeaver-bin}/bin/dbeaver";
        };

        api-client = {
          key = "P";  # P for Postman-like
          package = pkgs.insomnia;
          command = "${pkgs.insomnia}/bin/insomnia";
        };
      };
    };
  };

  # Example of gaming-focused keybinds
  den.aspects.gaming-keybinds = {
    description = "Gaming-focused keybind overrides";

    homeManager = { config, pkgs, lib, ... }: {
      desktop.keybinds.apps = {
        # Gaming applications
        steam = {
          key = "S";
          package = pkgs.steam;
          command = "${pkgs.steam}/bin/steam";
        };

        discord = {
          key = "D";
          package = pkgs.discord;
          command = "${pkgs.discord}/bin/discord";
        };

        obs = {
          key = "O";
          package = pkgs.obs-studio;
          command = "${pkgs.obs-studio}/bin/obs";
        };
      };

      # Gaming-specific system functions
      desktop.keybinds.system = {
        # Game mode toggle
        game-mode = {
          key = "F12";
          command = "gamemode-toggle";
        };

        # Recording shortcuts
        start-recording = {
          key = "F9";
          command = "obs-cli recording start";
        };

        stop-recording = {
          key = "F10";
          command = "obs-cli recording stop";
        };
      };
    };
  };
}
