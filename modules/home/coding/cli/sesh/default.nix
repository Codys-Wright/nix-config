{
  options,
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.coding.cli.sesh;
in
{
  options.${namespace}.coding.cli.sesh = with types; {
    enable = mkBoolOpt false "Enable sesh terminal session management";
  };

  config = mkIf cfg.enable {
    # Enable fzf tmux integration (required for sesh)
    programs.fzf.tmux.enableShellIntegration = true;
    
    # Use Home Manager's built-in sesh module
    programs.sesh = {
      enable = true;
      enableAlias = true;
      enableTmuxIntegration = true;
      icons = true;
      tmuxKey = "T";  # Use T instead of default 's'
      
      # Custom sesh configuration
      settings = {
        # Blacklist certain directories from showing up
        blacklist = [ "scratch" "tmp" ".cache" ];
        
        # Sort order for session types
        sort_order = [ "config" "tmux" "tmuxinator" "zoxide" ];
        
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
            windows = [ "nvim" "git" "mprocs" ];
          }
          {
            name = "Config";
            path = "~/nix-config";
            startup_command = "nvim";
            preview_command = "eza --all --git --icons --color=always {}";
            windows = [ "nvim" "git" ];
          }
        ];
      };
    };

    # Additional tmux configuration for sesh
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
}
