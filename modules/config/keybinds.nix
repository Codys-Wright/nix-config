# Desktop Keybind Abstractions
# Define keybinds and their associated applications independent of desktop environment
{ lib,
  FTS, ... }:
{
  FTS.desktop-keybinds = {
    description = "Desktop keybind abstractions with application mapping";

    homeManager = { config, pkgs, lib, ... }: {
      # Define keybind mappings and their associated applications
      options.desktop.keybinds = with lib.types; {
        # Modifier keys configuration
        mod = lib.mkOption {
          type = str;
          default = "SUPER";
          description = "Primary modifier key";
        };

        shiftMod = lib.mkOption {
          type = str;
          default = "SUPER_SHIFT";
          description = "Shift modifier combination";
        };

        altMod = lib.mkOption {
          type = str;
          default = "ALT";
          description = "Alt modifier key";
        };

        # Application keybind mappings
        apps = {
          terminal = {
            key = lib.mkOption {
              type = str;
              default = "RETURN";
              description = "Key to bind for terminal";
            };
            package = lib.mkOption {
              type = package;
              default = pkgs.kitty;
              description = "Terminal package";
            };
            command = lib.mkOption {
              type = str;
              default = "${config.desktop.keybinds.apps.terminal.package}/bin/kitty";
              description = "Command to launch terminal";
            };
          };

          browser = {
            key = lib.mkOption {
              type = str;
              default = "B";
              description = "Key to bind for browser";
            };
            package = lib.mkOption {
              type = package;
              default = pkgs.librewolf;
              description = "Browser package";
            };
            command = lib.mkOption {
              type = str;
              default = "${config.desktop.keybinds.apps.browser.package}/bin/librewolf";
              description = "Command to launch browser";
            };
          };

          files = {
            key = lib.mkOption {
              type = str;
              default = "E";
              description = "Key to bind for file manager";
            };
            package = lib.mkOption {
              type = lib.types.nullOr package;
              default = if pkgs.stdenv.isDarwin then null else pkgs.nautilus;
              description = "File manager package";
            };
            command = lib.mkOption {
              type = str;
              default = if pkgs.stdenv.isDarwin then "open -a Finder" else "${config.desktop.keybinds.apps.files.package}/bin/nautilus";
              description = "Command to launch file manager";
            };
          };

          notes = {
            key = lib.mkOption {
              type = str;
              default = "N";
              description = "Key to bind for notes";
            };
            package = lib.mkOption {
              type = package;
              default = pkgs.obsidian;
              description = "Notes application package";
            };
            command = lib.mkOption {
              type = str;
              default = "${config.desktop.keybinds.apps.notes.package}/bin/obsidian";
              description = "Command to launch notes app";
            };
          };

          ai = {
            key = lib.mkOption {
              type = str;
              default = "A";
              description = "Key to bind for AI";
            };
            package = lib.mkOption {
              type = nullOr package;
              default = null;
              description = "AI application package (if any)";
            };
            command = lib.mkOption {
              type = str;
              default = "${config.desktop.keybinds.apps.browser.command} https://chatgpt.com";
              description = "Command to launch AI interface";
            };
          };

          editor = {
            key = lib.mkOption {
              type = str;
              default = "V";
              description = "Key to bind for editor";
            };
            package = lib.mkOption {
              type = package;
              default = pkgs.neovim;
              description = "Code editor package";
            };
            command = lib.mkOption {
              type = str;
              default = "${config.desktop.keybinds.apps.terminal.command} -e ${config.desktop.keybinds.apps.editor.package}/bin/nvim";
              description = "Command to launch editor";
            };
          };

          music = {
            key = lib.mkOption {
              type = str;
              default = "M";
              description = "Key to bind for music";
            };
            package = lib.mkOption {
              type = package;
              default = pkgs.spotify;
              description = "Music player package";
            };
            command = lib.mkOption {
              type = str;
              default = "${config.desktop.keybinds.apps.music.package}/bin/spotify";
              description = "Command to launch music player";
            };
          };

          password-manager = {
            key = lib.mkOption {
              type = str;
              default = "K";
              description = "Key to bind for password manager";
            };
            package = lib.mkOption {
              type = package;
              default = pkgs.bitwarden-desktop;
              description = "Password manager package";
            };
            command = lib.mkOption {
              type = str;
              default = "${config.desktop.keybinds.apps.password-manager.package}/bin/bitwarden";
              description = "Command to launch password manager";
            };
          };

          launcher = {
            key = lib.mkOption {
              type = str;
              default = "SPACE";
              description = "Key to bind for launcher";
            };
            package = lib.mkOption {
              type = lib.types.nullOr package;
              default = if pkgs.stdenv.isDarwin then null else pkgs.rofi;
              description = "Application launcher package";
            };
            command = lib.mkOption {
              type = str;
              default = if pkgs.stdenv.isDarwin then "open -a 'Raycast'" else "${config.desktop.keybinds.apps.launcher.package}/bin/rofi -show drun";
              description = "Command to launch application launcher";
            };
          };
        };

        # System function keybinds
        system = {
          lock = {
            key = lib.mkOption {
              type = str;
              default = "L";
              description = "Key to bind for lock";
            };
            command = lib.mkOption {
              type = str;
              default = "hyprlock"; # Will be desktop-environment specific
              description = "Command to lock screen";
            };
          };

          power-menu = {
            key = lib.mkOption {
              type = str;
              default = "X";
              description = "Key to bind for power menu";
            };
            command = lib.mkOption {
              type = str;
              default = "power-menu"; # Custom script
              description = "Command to show power menu";
            };
          };
        };

        # Window management keybinds (universal)
        window = {
          close = {
            key = lib.mkOption {
              type = str;
              default = "Q";
              description = "Key to bind for closing window";
            };
            action = lib.mkOption {
              type = str;
              default = "close-window";
              description = "Window close action";
            };
          };

          toggle-floating = {
            key = lib.mkOption {
              type = str;
              default = "T";
              description = "Key to bind for toggle floating";
            };
            action = lib.mkOption {
              type = str;
              default = "toggle-floating";
              description = "Toggle floating action";
            };
          };

          toggle-fullscreen = {
            key = lib.mkOption {
              type = str;
              default = "F";
              description = "Key to bind for toggle fullscreen";
            };
            action = lib.mkOption {
              type = str;
              default = "toggle-fullscreen";
              description = "Toggle fullscreen action";
            };
          };

          focus-left = {
            key = lib.mkOption {
              type = str;
              default = "H";
              description = "Key to bind for focus left";
            };
            action = lib.mkOption {
              type = str;
              default = "focus-left";
              description = "Focus left action";
            };
          };

          focus-down = {
            key = lib.mkOption {
              type = str;
              default = "J";
              description = "Key to bind for focus down";
            };
            action = lib.mkOption {
              type = str;
              default = "focus-down";
              description = "Focus down action";
            };
          };

          focus-up = {
            key = lib.mkOption {
              type = str;
              default = "K";
              description = "Key to bind for focus up";
            };
            action = lib.mkOption {
              type = str;
              default = "focus-up";
              description = "Focus up action";
            };
          };

          focus-right = {
            key = lib.mkOption {
              type = str;
              default = "L";
              description = "Key to bind for focus right";
            };
            action = lib.mkOption {
              type = str;
              default = "focus-right";
              description = "Focus right action";
            };
          };
        };

        # Helper functions to generate bindings for desktop environments
        generateAppBindings = lib.mkOption {
          type = attrsOf str;
          default = with config.desktop.keybinds; {
            "${mod},${apps.terminal.key}" = apps.terminal.command;
            "${mod},${apps.browser.key}" = apps.browser.command;
            "${mod},${apps.files.key}" = apps.files.command;
            "${mod},${apps.notes.key}" = apps.notes.command;
            "${mod},${apps.ai.key}" = apps.ai.command;
            "${mod},${apps.editor.key}" = apps.editor.command;
            "${mod},${apps.music.key}" = apps.music.command;
            "${mod},${apps.password-manager.key}" = apps.password-manager.command;
            "${mod},${apps.launcher.key}" = apps.launcher.command;
            "${mod},${system.lock.key}" = system.lock.command;
            "${mod},${system.power-menu.key}" = system.power-menu.command;
          };
          description = "Generated app keybind mappings";
        };

        generateWindowBindings = lib.mkOption {
          type = attrsOf str;
          default = with config.desktop.keybinds; {
            "${mod},${window.close.key}" = window.close.action;
            "${mod},${window.toggle-floating.key}" = window.toggle-floating.action;
            "${mod},${window.toggle-fullscreen.key}" = window.toggle-fullscreen.action;
            "${mod},${window.focus-left.key}" = window.focus-left.action;
            "${mod},${window.focus-down.key}" = window.focus-down.action;
            "${mod},${window.focus-up.key}" = window.focus-up.action;
            "${mod},${window.focus-right.key}" = window.focus-right.action;
          };
          description = "Generated window management keybind mappings";
        };
      };

      # Install the defined application packages
      config = {
        home.packages = with config.desktop.keybinds.apps; lib.filter (pkg: pkg != null) [
          terminal.package
          browser.package
          files.package
          notes.package
          editor.package
          music.package
          password-manager.package
          launcher.package
        ] ++ lib.optionals (ai.package != null) [ ai.package ];
      };
    };
  };
}
