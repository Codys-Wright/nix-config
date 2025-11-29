# CLI tools aspect for CodyWright's development environment
{
  FTS, ... }:
{
  FTS.cli-tools = {
    description = "Essential CLI tools for development";

    homeManager =
          { pkgs, lib, ... }:
          lib.mkIf pkgs.stdenvNoCC.isDarwin {
            # Direnv - better than native direnv nix functionality
            programs.direnv = {
              enable = true;
              enableBashIntegration = true;
              enableZshIntegration = true;
              nix-direnv.enable = true;
            };

            # Btop - system monitor with vim keys
            programs.btop = {
              enable = true;
              settings = {
                vim_keys = true;
              };
            };

            # Atuin - shell history
            programs.atuin = {
              enable = true;
              enableZshIntegration = true;
            };

            # Eza - modern ls replacement
            programs.eza = {
              enable = true;
              icons = "auto";
              extraOptions = [
                "--group-directories-first"
                "--no-quotes"
                "--git-ignore"
                "--icons=always"
              ];
            };

            # Fzf - fuzzy finder with custom colors
            programs.fzf = {
              enable = true;
              enableZshIntegration = true;
              tmux.enableShellIntegration = true;
              colors = lib.mkForce {
                "fg+" = "#007acc";
                "bg+" = "-1";
                "fg" = "#ffffff";
                "bg" = "-1";
                "prompt" = "#666666";
                "pointer" = "#007acc";
              };
              defaultOptions = [
                "--margin=1"
                "--layout=reverse"
                "--border=rounded"
                "--info='hidden'"
                "--header=''"
                "--prompt='/ '"
                "-i"
                "--no-bold"
              ];
            };

            # Zoxide - smart cd
            programs.zoxide = {
              enable = true;
              enableZshIntegration = true;
              enableBashIntegration = true;
              enableFishIntegration = true;
            };

            # Yazi - file manager
            programs.yazi = {
              enable = true;
              enableZshIntegration = true;
              enableBashIntegration = true;
              shellWrapperName = "y";
            };

            # Sesh - terminal session management
            programs.sesh = {
              enable = true;
              enableAlias = true;
              enableTmuxIntegration = true;
              icons = true;
              tmuxKey = "T"; # Use T instead of default 's'

              settings = {
                # Blacklist certain directories from showing up
                blacklist = [
                  "scratch"
                  "tmp"
                  ".cache"
                ];

                # Sort order for session types
                sort_order = [
                  "config"
                  "tmux"
                  "tmuxinator"
                  "zoxide"
                ];

                # Default session configuration
                default_session = {
                  startup_command = "nvim";
                  preview_command = "eza --all --git --icons --color=always {}";
                };

                # Custom windows for sessions
                window = [
                  {
                    name = "nvim";
                    startup_script = "nvim";
                  }
                  {
                    name = "opencode";
                    startup_script = "opencode";
                  }
                  {
                    name = "mprocs";
                    startup_script = "mprocs";
                  }
                  {
                    name = "git";
                    startup_script = "lazygit";
                  }
                ];

                # Example session configurations
                session = [
                  {
                    name = "Development";
                    path = "~/dev";
                    startup_command = "nvim";
                    preview_command = "eza --all --git --icons --color=always {}";
                    windows = [
                      "nvim"
                      "git"
                      "mprocs"
                    ];
                  }
                  {
                    name = "Config";
                    path = "~/nix-config";
                    startup_command = "nvim";
                    preview_command = "eza --all --git --icons --color=always {}";
                    windows = [
                      "nvim"
                      "git"
                    ];
                  }
                ];
              };
            };

            # Tmux configuration for sesh
            programs.tmux = {
              enable = true;
              extraConfig = ''
                # Session management improvements
                bind-key x kill-pane # skip "kill-pane 1? (y/n)" prompt
                set -g detach-on-destroy off  # don't exit from tmux when closing a session

                # Additional sesh bindings
                bind -N "last-session (via sesh) " L run-shell "sesh last"
                bind -N "switch to root session (via sesh) " 9 run-shell "sesh connect --root \'$(pwd)\'"

                # Sesh with gum filter popup
                bind-key "R" display-popup -E -w 40% "sesh connect \"$(
                  sesh list -i -H | gum filter --value \"$(sesh root)\" --limit 1 --fuzzy --no-sort --placeholder 'Pick a sesh' --prompt='⚡'
                )\""
              '';
            };

          };

    # NixOS system packages
    nixos = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        just
      ];
    };
  };
}
