{ config, lib, pkgs, namespace, ... }:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.coding.tools;
in
{
  options.${namespace}.coding.tools = with types; {
    enable = mkBoolOpt false "Enable dev tools";
  };

  config = mkIf cfg.enable {
    # Enable individual tools
    ${namespace}.coding.tools = {
      git = enabled;
      docker = enabled;
      lazygit = enabled;
    };

    # Development tools packages
    home.packages = with pkgs; [
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
    ];
  };
} 