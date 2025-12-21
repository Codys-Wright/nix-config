# Zellij terminal multiplexer aspect
{
  FTS,
  inputs,
  ...
}: {
  flake-file.inputs.zellij-nix.url = "github:a-kenji/zellij-nix";

  FTS.coding._.terminals._.zellij = {
    description = "Zellij terminal multiplexer with custom configuration";

    # Darwin-specific configuration
    darwin = {
      config,
      pkgs,
      lib,
      ...
    }: {
      # Darwin system-level configurations
      # Note: pbcopy is a macOS system utility, available by default
      # No additional system packages needed for clipboard integration on macOS
      environment.systemPackages = with pkgs; [
        # zellij is installed via home-manager, but can be added here if needed
      ];
    };

    # NixOS-specific configuration
    nixos = {
      config,
      pkgs,
      lib,
      ...
    }: {
      # Linux-specific clipboard utilities for zellij
      environment.systemPackages = with pkgs; [
        wl-clipboard # Wayland
        xclip # X11
      ];
    };

    # Home Manager configuration (works on both Darwin and Linux)
    homeManager = {
      config,
      pkgs,
      lib,
      ...
    }: let
      # Clipboard command based on platform
      copyCommand =
        if pkgs.stdenv.hostPlatform.isLinux
        then "wl-copy"
        else if pkgs.stdenv.hostPlatform.isDarwin
        then "pbcopy"
        else "";

      # Path where the plugin will be installed
      # The plugin should be installed manually with: zellij plugin install jyscao/zellij-nvim-nav-plugin
      # This will install it to ~/.local/share/zellij/plugins/zellij-nvim-nav-plugin.wasm
      nvimNavPluginPath = "${config.home.homeDirectory}/.local/share/zellij/plugins/zellij-nvim-nav-plugin.wasm";
    in {
      # Enable Zellij via Home Manager
      programs.zellij = {
        enable = true;
        enableFishIntegration = false; # Disable auto-start
        enableZshIntegration = false; # Disable auto-start
        enableBashIntegration = false; # Disable auto-start

        # Tokyo Night theme definition
        # Based on Tokyo Night color scheme
        # Note: Each theme file needs to be wrapped in a 'themes' node
        themes = {
          tokyonight = ''
            themes {
              tokyonight {
              text_unselected {
                base 169 177 214
                background 26 27 38
                emphasis_0 247 118 142
                emphasis_1 156 207 216
                emphasis_2 224 175 104
                emphasis_3 187 154 246
              }
              text_selected {
                base 192 202 245
                background 36 40 59
                emphasis_0 247 118 142
                emphasis_1 156 207 216
                emphasis_2 224 175 104
                emphasis_3 187 154 246
              }
              ribbon_unselected {
                base 169 177 214
                background 36 40 59
                emphasis_0 247 118 142
                emphasis_1 156 207 216
                emphasis_2 224 175 104
                emphasis_3 187 154 246
              }
              ribbon_selected {
                base 192 202 245
                background 48 52 70
                emphasis_0 247 118 142
                emphasis_1 156 207 216
                emphasis_2 224 175 104
                emphasis_3 187 154 246
              }
              table_title {
                base 192 202 245
                background 26 27 38
                emphasis_0 247 118 142
                emphasis_1 156 207 216
                emphasis_2 224 175 104
                emphasis_3 187 154 246
              }
              table_cell_unselected {
                base 169 177 214
                background 26 27 38
                emphasis_0 247 118 142
                emphasis_1 156 207 216
                emphasis_2 224 175 104
                emphasis_3 187 154 246
              }
              table_cell_selected {
                base 192 202 245
                background 36 40 59
                emphasis_0 247 118 142
                emphasis_1 156 207 216
                emphasis_2 224 175 104
                emphasis_3 187 154 246
              }
              list_unselected {
                base 169 177 214
                background 26 27 38
                emphasis_0 247 118 142
                emphasis_1 156 207 216
                emphasis_2 224 175 104
                emphasis_3 187 154 246
              }
              list_selected {
                base 192 202 245
                background 36 40 59
                emphasis_0 247 118 142
                emphasis_1 156 207 216
                emphasis_2 224 175 104
                emphasis_3 187 154 246
              }
              frame_unselected {
                base 36 40 59
                background 26 27 38
                emphasis_0 247 118 142
                emphasis_1 156 207 216
                emphasis_2 224 175 104
                emphasis_3 187 154 246
              }
              frame_selected {
                base 48 52 70
                background 26 27 38
                emphasis_0 247 118 142
                emphasis_1 156 207 216
                emphasis_2 224 175 104
                emphasis_3 187 154 246
              }
              frame_highlight {
                base 187 154 246
                background 26 27 38
                emphasis_0 247 118 142
                emphasis_1 156 207 216
                emphasis_2 224 175 104
                emphasis_3 187 154 246
              }
              exit_code_success {
                base 156 207 216
                background 26 27 38
                emphasis_0 247 118 142
                emphasis_1 156 207 216
                emphasis_2 224 175 104
                emphasis_3 187 154 246
              }
              exit_code_error {
                base 247 118 142
                background 26 27 38
                emphasis_0 247 118 142
                emphasis_1 156 207 216
                emphasis_2 224 175 104
                emphasis_3 187 154 246
              }
              multiplayer_user_colors {
                player_1 247 118 142
                player_2 156 207 216
                player_3 224 175 104
                player_4 187 154 246
                player_5 125 207 255
                player_6 255 184 108
                player_7 255 85 85
                player_8 80 250 123
                player_9 255 121 198
                player_10 139 233 253
              }
            }
            }
          '';
        };

        # UI configuration
        settings = {
          # Set tokyonight theme
          theme = "tokyonight";

          # UI configuration
          pane_frames = false;
          simplified_ui = false;
          copy_on_select = true;
          on_force_close = "detach";
          show_startup_tips = false;
          support_kitty_keyboard_protocol = true;

          # Default shell
          default_shell = "${pkgs.fish}/bin/fish";

          # Scrollback and session settings
          scrollback_lines_to_serialize = 10000;
          session_serialization = true;

          # Clipboard integration
          copy_command = copyCommand;

          # UI pane frames
          ui = {
            pane_frames = {
              rounded_corners = true;
              hide_session_name = true;
            };
          };
        };

        # Extra config for Neovim-friendly keybindings and zellij-nvim-nav-plugin
        extraConfig = ''
          // Zellij nvim navigation plugin configuration
          // This plugin enables seamless navigation between Neovim and Zellij
          plugins {
            nvim-nav location="file:${nvimNavPluginPath}"
          }

          load_plugins {
            nvim-nav
          }

          // Keybindings configuration for Neovim compatibility
          // Strategy: Clear Normal mode defaults and use Tmux mode for Zellij features
          // This allows Neovim to use Ctrl keys freely without conflicts
          keybinds {
            // Clear all defaults in Normal mode so Neovim can use Ctrl keys freely
            normal clear-defaults=true {
              // Only bind Ctrl+f to switch to Tmux mode
              // This is the main way to access Zellij features
              bind "Ctrl f" { SwitchToMode "Tmux"; }

              // Unbind Ctrl+b (default tmux mode) since we're using Ctrl+f
              unbind "Ctrl b"

              // Navigation bindings using zellij-nvim-nav-plugin
              // The plugin handles navigation intelligently:
              // - If current pane is Neovim: sends key to Neovim (handled by zellij-nav.nvim)
              // - If current pane is NOT Neovim: moves focus in Zellij
              // Single-byte payloads for Ctrl key combinations:
              // Ctrl+h = 8, Ctrl+j = 10, Ctrl+k = 11, Ctrl+l = 12
              bind "Ctrl h" { MessagePlugin { name "nvim_nav_left"; payload "8"; }; }
              bind "Ctrl j" { MessagePlugin { name "nvim_nav_down"; payload "10"; }; }
              bind "Ctrl k" { MessagePlugin { name "nvim_nav_up"; payload "11"; }; }
              bind "Ctrl l" { MessagePlugin { name "nvim_nav_right"; payload "12"; }; }
            }

            // Tmux mode: Custom keybindings for quick access to Zellij features
            // Access with Ctrl+f, then use single keys to switch modes
            tmux clear-defaults=true {
              // Exit tmux mode (send Ctrl+f to terminal or switch back to Normal)
              bind "Ctrl f" { Write 2; SwitchToMode "Normal"; }
              bind "Esc" { SwitchToMode "Normal"; }

              // Quick mode switching
              bind "g" { SwitchToMode "Locked"; }
              bind "p" { SwitchToMode "Pane"; }
              bind "t" { SwitchToMode "Tab"; }
              bind "n" { SwitchToMode "Resize"; }
              bind "h" { SwitchToMode "Move"; }
              bind "s" { SwitchToMode "Scroll"; }
              bind "o" { SwitchToMode "Session"; }
              bind "q" { Quit; }
            }
          }
        '';
      };

      # Note: zellij-nvim-nav-plugin should be installed manually with:
      # zellij plugin install jyscao/zellij-nvim-nav-plugin
      # The plugin will be installed to ~/.local/share/zellij/plugins/zellij-nvim-nav-plugin.wasm
      # and the config will reference it automatically

      # Note: Zellij auto-attach and auto-start are disabled
      # To start zellij manually, just run: zellij
      # To attach to an existing session: zellij attach

      # Shell aliases for zellij
      programs.zsh.shellAliases = {
        "za" = "zellij attach";
        "zl" = "zellij list-sessions";
        "zn" = "zellij new-session";
        "zk" = "zellij kill-session";
        "zr" = "zellij run";
      };
    };
  };
}
