# Essential system utilities
{
  FTS,
  ...
}:
{
  FTS.system._.utils = {
    description = "Essential system utilities - vim, curl, git, etc.";

    nixos = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        vim       # Text editor
        curl      # HTTP client
        wget      # File downloader
        git       # Version control
        htop      # Process monitor
        tmux      # Terminal multiplexer
      ];
    };
  };
}

