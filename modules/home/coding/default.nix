{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.coding;
in
{
  options.${namespace}.coding = with types; {
    enable = mkBoolOpt false "Enable coding environment";
    languages = mkBoolOpt false "Enable programming language support";
    tools = mkBoolOpt false "Enable development tools";
    editors = mkBoolOpt false "Enable code editors";
    databases = mkBoolOpt false "Enable database tools";
    containerization = mkBoolOpt false "Enable Docker and container tools";
    cloud = mkBoolOpt false "Enable cloud development tools";
    all = mkBoolOpt false "Enable all coding features";
  };

  config = mkIf cfg.enable {
    # Enable language support
    ${namespace}.coding.lang = {
      enable = mkIf (cfg.languages || cfg.all) true;
    };

    # Development tools
    home.packages =
      with pkgs;
      (optionals (cfg.tools || cfg.all) [
        # Version control
        git
        git-lfs
        gh # GitHub CLI
        gitlab-runner

        # Build tools
        gnumake
        cmake
        meson
        ninja
        pkg-config

        # Debugging tools
        gdb
        lldb
        valgrind

        # Performance tools
        perf-tools
        hyperfine

        # Documentation
        pandoc
        graphviz

        # API development
        postman
        insomnia

        # Text processing
        jq
        yq
        xmlstarlet

        # Network tools
        curl
        wget
        httpie
        netcat
        nmap
        wireshark

        # File tools
        tree
        fd
        ripgrep
        bat
        eza

        # Archive tools
        unzip
        zip
        p7zip

        # Monitoring
        htop
        btop
        iotop

        # Development utilities
        watchman
        entr
        tmux
        screen
      ])

      ++ (optionals (cfg.editors || cfg.all) [
        # Editors
        vim
        neovim
        emacs

        # IDEs
        jetbrains.idea-community
        jetbrains.webstorm
        jetbrains.pycharm-community

        # VS Code alternatives
        code-cursor
        vscodium
      ])

      ++ (optionals (cfg.databases || cfg.all) [
        # Database tools
        postgresql
        mysql80
        sqlite
        redis
        mongodb

        # Database management
        dbeaver
        pgadmin4

        # Database CLI tools
        mycli
        pgcli
        sqlite-utils
      ])

      ++ (optionals (cfg.containerization || cfg.all) [
        # Container tools
        docker
        docker-compose
        podman
        podman-compose

        # Kubernetes
        kubectl
        k9s
        helm
        kustomize

        # Container utilities
        dive # Docker image explorer
        lazydocker
      ])

      ++ (optionals (cfg.cloud || cfg.all) [
        # Cloud CLIs
        awscli2
        google-cloud-sdk
        azure-cli

        # Infrastructure as Code
        terraform
        terragrunt
        ansible

        # Cloud utilities
        k6 # Load testing
        grafana-loki
      ]);

    # Global Git configuration
    programs.git = mkIf (cfg.tools || cfg.all) {
      enable = mkDefault true;
      delta.enable = mkDefault true;
      extraConfig = {
        init.defaultBranch = mkDefault "main";
        pull.rebase = mkDefault true;
        push.autoSetupRemote = mkDefault true;
        core.autocrlf = mkDefault false;
        core.safecrlf = mkDefault false;
        rebase.autoStash = mkDefault true;
        merge.conflictStyle = mkDefault "diff3";
        diff.algorithm = mkDefault "histogram";
        branch.sort = mkDefault "-committerdate";
        tag.sort = mkDefault "version:refname";
      };
      aliases = {
        st = "status";
        co = "checkout";
        br = "branch";
        ci = "commit";
        lg = "log --oneline --graph --decorate";
        unstage = "reset HEAD --";
        last = "log -1 HEAD";
        visual = "!gitk";
        amend = "commit --amend";
        pushf = "push --force-with-lease";
        recent = "branch --sort=-committerdate";
      };
    };

    # Direnv for project environments
    programs.direnv = mkIf (cfg.tools || cfg.all) {
      enable = mkDefault true;
      enableZshIntegration = mkDefault true;
      enableBashIntegration = mkDefault true;
      nix-direnv.enable = mkDefault true;
    };

    # Tmux for terminal multiplexing
    programs.tmux = mkIf (cfg.tools || cfg.all) {
      enable = mkDefault true;
      terminal = mkDefault "screen-256color";
      historyLimit = mkDefault 10000;
      keyMode = mkDefault "vi";
      extraConfig = mkDefault ''
        # Enable mouse support
        set -g mouse on

        # Start windows and panes at 1, not 0
        set -g base-index 1
        setw -g pane-base-index 1

        # Renumber windows when one is closed
        set -g renumber-windows on

        # Increase scrollback buffer size
        set -g history-limit 50000

        # Display messages for 2 seconds
        set -g display-time 2000

        # Refresh status line every 5 seconds
        set -g status-interval 5

        # Upgrade $TERM
        set -g default-terminal "screen-256color"

        # Enable RGB colour if running in xterm
        set-option -sa terminal-overrides ",xterm*:Tc"

        # Change default meta key to same as screen
        unbind C-b
        set -g prefix C-a

        # Form vim/tmux d/y buffer sync
        set -g focus-events on

        # Use vim keybindings in copy mode
        setw -g mode-keys vi

        # Setup 'v' to begin selection, just like Vim
        bind-key -T copy-mode-vi 'v' send -X begin-selection

        # Setup 'y' to yank (copy), just like Vim
        bind-key -T copy-mode-vi 'y' send -X copy-pipe-and-cancel "pbcopy"
        bind-key -T copy-mode-vi 'V' send -X select-line
        bind-key -T copy-mode-vi 'r' send -X rectangle-toggle

        # Bind ']' to use the clipboard
        bind ] run "reattach-to-user-namespace pbpaste | tmux load-buffer - && tmux paste-buffer"
      '';
    };

    # Environment variables for development
    home.sessionVariables = mkIf (cfg.tools || cfg.all) {
      EDITOR = mkDefault "vim";
      VISUAL = mkDefault "vim";
      PAGER = mkDefault "less";
      LESS = mkDefault "-R";
      MANPAGER = mkDefault "less -X";
    };

    # XDG directories for development
    xdg.configFile = mkIf (cfg.tools || cfg.all) {
      "git/ignore".text = ''
        # OS generated files
        .DS_Store
        .DS_Store?
        ._*
        .Spotlight-V100
        .Trashes
        ehthumbs.db
        Thumbs.db

        # Editor files
        *.swp
        *.swo
        *~
        .vscode/
        .idea/
        *.sublime-project
        *.sublime-workspace

        # Dependencies
        node_modules/
        .npm/
        .yarn/
        vendor/

        # Build outputs
        dist/
        build/
        target/
        *.log

        # Environment files
        .env
        .env.local
        .env.*.local

        # Cache directories
        .cache/
        .tmp/
        .temp/

        # Package manager locks (when appropriate)
        # Uncomment these if you want to ignore lock files
        # package-lock.json
        # yarn.lock
        # pnpm-lock.yaml
        # Cargo.lock
        # Pipfile.lock
      '';
    };
  };
}
