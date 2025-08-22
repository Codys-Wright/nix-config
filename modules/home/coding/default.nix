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
      (optionals (cfg.editors || cfg.all) [
        # Editors
        vim
        neovim
        emacs

        # IDEs
        jetbrains.idea-community
        jetbrains.webstorm
        jetbrains.pycharm-community

        # VS Code alternatives
        vscodium
        # Note: code-cursor is excluded to avoid conflicts with zed-editor
        # Use the dedicated zed-editor module instead
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

    # Environment variables for development
    home.sessionVariables = mkIf (cfg.all) {
      EDITOR = mkDefault "vim";
      VISUAL = mkDefault "vim";
      PAGER = mkDefault "less";
      LESS = mkDefault "-R";
      MANPAGER = mkDefault "less -X";
    };

    # XDG directories for development
    xdg.configFile = mkIf (cfg.all) {
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
