# Tmux terminal multiplexer aspect
{
  FTS, ... }:
{
  FTS.tmux = {
    description = "Tmux terminal multiplexer with custom configuration and plugins";

    homeManager = { config, pkgs, lib, ... }: {
      programs.tmux = {
        enable = true;
        mouse = true;
        shell = "${pkgs.zsh}/bin/zsh";
        prefix = "C-a";
        terminal = "tmux-256color";
        keyMode = "vi";
        baseIndex = 1;

        # Automatically renumber windows when one is closed
        renumberWindows = true;

        extraConfig = ''
          # Set true color support
          set-option -sa terminal-features ',kitty:RGB'
          set-option -ga terminal-overrides ',kitty:Tc'

          # Enable clipboard integration
          set -g set-clipboard on

          # Reload config binding
          bind r source-file ~/.config/tmux/tmux.conf \; display "Reloaded!"

          # Better window splitting
          bind | split-window -h -c "#{pane_current_path}"
          bind - split-window -v -c "#{pane_current_path}"
          bind c new-window -c "#{pane_current_path}"

          # Vim-like pane navigation
          bind h select-pane -L
          bind j select-pane -D
          bind k select-pane -U
          bind l select-pane -R

          # Pane resizing
          bind -r H resize-pane -L 5
          bind -r J resize-pane -D 5
          bind -r K resize-pane -U 5
          bind -r L resize-pane -R 5

          # Better copy mode
          bind v copy-mode
          bind -T copy-mode-vi v send-keys -X begin-selection
          bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "pbcopy"
          bind -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "pbcopy"

          # Status bar configuration
          set -g status-position top
          set -g status-interval 1

          # Window status format
          set -g window-status-current-format "#[fg=colour232,bg=colour39] #I #W "
          set -g window-status-format "#[fg=colour232,bg=colour244] #I #W "

          # Don't exit tmux when closing a session
          set -g detach-on-destroy off

          # Faster command sequences
          set -s escape-time 10

          # Increase repeat time for repeatable commands
          set -g repeat-time 1000

          # Increase scrollback buffer size
          set -g history-limit 50000

          # Focus events enabled for terminals that support them
          set -g focus-events on

          # Super useful when using "grouped sessions" and multi-monitor setup
          setw -g aggressive-resize on
        '';

        plugins = with pkgs.tmuxPlugins; [
          {
            plugin = catppuccin;
            extraConfig = ''
              set -g @catppuccin_flavour 'mocha'
              set -g @catppuccin_window_left_separator ""
              set -g @catppuccin_window_right_separator " "
              set -g @catppuccin_window_middle_separator " █"
              set -g @catppuccin_window_number_position "right"
              set -g @catppuccin_window_default_fill "number"
              set -g @catppuccin_window_default_text "#W"
              set -g @catppuccin_window_current_fill "number"
              set -g @catppuccin_window_current_text "#W"
              set -g @catppuccin_status_modules_right "directory session"
              set -g @catppuccin_status_left_separator  " "
              set -g @catppuccin_status_right_separator ""
              set -g @catppuccin_status_fill "icon"
              set -g @catppuccin_status_connect_separator "no"
              set -g @catppuccin_directory_text "#{pane_current_path}"
            '';
          }
          {
            plugin = vim-tmux-navigator;
            extraConfig = ''
              # Smart pane switching with awareness of Vim splits.
              # See: https://github.com/christoomey/vim-tmux-navigator
              is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
                  | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|l?n?vim?x?|fzf)(diff)?$'"
              bind-key -n 'C-h' if-shell "$is_vim" 'send-keys C-h'  'select-pane -L'
              bind-key -n 'C-j' if-shell "$is_vim" 'send-keys C-j'  'select-pane -D'
              bind-key -n 'C-k' if-shell "$is_vim" 'send-keys C-k'  'select-pane -U'
              bind-key -n 'C-l' if-shell "$is_vim" 'send-keys C-l'  'select-pane -R'
              tmux_version='$(tmux -V | sed -En "s/^tmux ([0-9]+(.[0-9]+)?).*/\1/p")'
              if-shell -b '[ "$(echo "$tmux_version < 3.0" | bc)" = 1 ]' \
                  "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\'  'select-pane -l'"
              if-shell -b '[ "$(echo "$tmux_version >= 3.0" | bc)" = 1 ]' \
                  "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\\\'  'select-pane -l'"

              bind-key -T copy-mode-vi 'C-h' select-pane -L
              bind-key -T copy-mode-vi 'C-j' select-pane -D
              bind-key -T copy-mode-vi 'C-k' select-pane -U
              bind-key -T copy-mode-vi 'C-l' select-pane -R
              bind-key -T copy-mode-vi 'C-\' select-pane -l
            '';
          }
          {
            plugin = resurrect;
            extraConfig = ''
              set -g @resurrect-strategy-vim 'session'
              set -g @resurrect-strategy-nvim 'session'
              set -g @resurrect-capture-pane-contents 'on'
            '';
          }
          {
            plugin = continuum;
            extraConfig = ''
              set -g @continuum-restore 'on'
              set -g @continuum-boot 'on'
              set -g @continuum-save-interval '15'
            '';
          }
          sensible
          yank
          prefix-highlight
        ];
      };

      # Additional tmux utilities
      home.packages = with pkgs; [
        tmux
        tmuxinator

        # Clipboard utilities for tmux
        pbcopy # macOS
        wl-clipboard # Wayland
        xclip # X11
      ];

      # Shell aliases for tmux
      programs.zsh.shellAliases = {
        "ta" = "tmux attach-session -t";
        "tl" = "tmux list-sessions";
        "tn" = "tmux new-session -s";
        "tk" = "tmux kill-session -t";
      };
    };
  };
}
