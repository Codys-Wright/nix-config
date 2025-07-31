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
    enable = mkBoolOpt false "Whether or not to enable CLI configuration for the user.";
  };

  config = mkIf cfg.enable {
    # User-specific CLI packages
    home.packages = with pkgs; [
      # Core CLI tools
      curl
      wget
      git
      vim
      neovim
      tmux
      htop
      btop
      ripgrep
      fd
      fzf
      tree
      bat
      exa
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
      xsv
      csvkit
      
      # Development tools
      gcc
      gnumake
      cmake
      pkg-config
      
      # Version control
      git-crypt
      git-lfs
      
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
      
      # Shell history management
      atuin
    ];

    ${namespace} = {
      # Enable CLI-specific modules here as we create them
      programs.cli.atuin = enabled;
      
      # services = {
      #   cli-service = enabled;
      # };
    };
  };
} 