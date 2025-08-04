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
  cfg = config.${namespace}.coding.lang;
in
{
  options.${namespace}.coding.lang = with types; {
    enable = mkBoolOpt false "Enable programming language support";
    all = mkBoolOpt false "Enable all supported programming languages";
  };

  config = mkIf cfg.enable {
    # Enable individual language modules based on options
    ${namespace}.coding.lang.typescript.enable = mkIf cfg.all true;

    # Future language modules can be added here:
    # ${namespace}.coding.lang.python.enable = mkIf cfg.all true;
    # ${namespace}.coding.lang.rust.enable = mkIf cfg.all true;
    # ${namespace}.coding.lang.go.enable = mkIf cfg.all true;
    # ${namespace}.coding.lang.java.enable = mkIf cfg.all true;
    # ${namespace}.coding.lang.csharp.enable = mkIf cfg.all true;
    # ${namespace}.coding.lang.cpp.enable = mkIf cfg.all true;
    # ${namespace}.coding.lang.php.enable = mkIf cfg.all true;
    # ${namespace}.coding.lang.ruby.enable = mkIf cfg.all true;

    # Common development tools for all languages
    home.packages = with pkgs; [
      # Version control
      git
      git-lfs
      gh # GitHub CLI

      # Text editors and IDEs
      vim
      neovim

      # Build tools
      gnumake
      cmake

      # Documentation tools
      pandoc

      # Container tools
      docker-compose

      # API testing
      curl
      wget
      httpie

      # JSON/YAML tools
      jq
      yq

      # Process monitoring
      htop
      btop

      # File management
      tree
      fd
      ripgrep

      # Network tools
      netcat
      nmap

      # Archive tools
      unzip
      zip

      # Development utilities
      watchman
      entr
    ];

    # Configure Git globally if not already configured
    programs.git = {
      enable = mkDefault true;
      extraConfig = {
        init.defaultBranch = mkDefault "main";
        pull.rebase = mkDefault true;
        push.autoSetupRemote = mkDefault true;
        core.autocrlf = mkDefault false;
        core.safecrlf = mkDefault false;
      };
    };

    # Configure direnv for project-specific environments
    programs.direnv = {
      enable = mkDefault true;
      enableZshIntegration = mkDefault true;
      enableBashIntegration = mkDefault true;
      nix-direnv.enable = mkDefault true;
    };
  };
}
