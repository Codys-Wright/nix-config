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
  cfg = config.${namespace}.bundles.cli;
in
{
  options.${namespace}.bundles.cli = with types; {
    enable = mkBoolOpt false "Whether or not to enable CLI configuration.";
  };

  config = mkIf cfg.enable {
    # CLI-specific system packages
    environment.systemPackages = with pkgs; [
      # Core CLI tools
      curl
      wget
      git
      vim
      # neovim # Disabled - using flake nvim instead
      tmux
      htop
      btop
      ripgrep
      fd
      fzf
      tree
      bat
      eza
      du-dust
      procs
      bottom
      
      # Network tools
      nmap
      netcat
      mtr
      iftop
      iotop
      
      # System monitoring
      lsof
      strace
      ltrace
      perf-tools
      
      # File and text processing
      jq
      yq
      xan
      csvkit
      
      # Development tools
      gcc
      gnumake
      cmake
      pkg-config
      
      # Version control
      git-crypt
      git-lfs
      gh
      
      # Shell utilities
      zsh
      bash
      fish
      
      # Terminal utilities
      kitty
      alacritty
      wezterm
      
      # Package management
      nix-index
      nix-tree
    ];

    ${namespace} = {
      # Enable CLI-specific modules here as we create them
      # programs = {
      #   cli-tool = enabled;
      # };
      
      # services = {
      #   cli-service = enabled;
      # };
    };
  };
} 