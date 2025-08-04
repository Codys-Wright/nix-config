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
    typescript = mkBoolOpt false "Enable TypeScript/JavaScript development environment";
    python = mkBoolOpt false "Enable Python development environment";
    rust = mkBoolOpt false "Enable Rust development environment";
    go = mkBoolOpt false "Enable Go development environment";
    java = mkBoolOpt false "Enable Java development environment";
    csharp = mkBoolOpt false "Enable C# development environment";
    cpp = mkBoolOpt false "Enable C++ development environment";
    php = mkBoolOpt false "Enable PHP development environment";
    ruby = mkBoolOpt false "Enable Ruby development environment";
    all = mkBoolOpt false "Enable all supported programming languages";
  };

  config = mkIf cfg.enable {
    # Enable individual language modules based on options
    ${namespace}.coding.lang.typescript.enable = mkIf (cfg.typescript || cfg.all) true;

    # Future language modules can be added here:
    # ${namespace}.coding.lang.python.enable = mkIf (cfg.python || cfg.all) true;
    # ${namespace}.coding.lang.rust.enable = mkIf (cfg.rust || cfg.all) true;
    # ${namespace}.coding.lang.go.enable = mkIf (cfg.go || cfg.all) true;
    # ${namespace}.coding.lang.java.enable = mkIf (cfg.java || cfg.all) true;
    # ${namespace}.coding.lang.csharp.enable = mkIf (cfg.csharp || cfg.all) true;
    # ${namespace}.coding.lang.cpp.enable = mkIf (cfg.cpp || cfg.all) true;
    # ${namespace}.coding.lang.php.enable = mkIf (cfg.php || cfg.all) true;
    # ${namespace}.coding.lang.ruby.enable = mkIf (cfg.ruby || cfg.all) true;

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
