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
  cfg = config.${namespace}.bundles.common;
in
{
  options.${namespace}.bundles.common = with types; {
    enable = mkBoolOpt false "Whether or not to enable common bundle configuration.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # Terminal
      btop
      coreutils
      killall
      tldr
      wget

      # Video/Audio
      celluloid
      loupe

      # File Management
      unrar
      unzip
      zip

      bitwarden
      fastfetch

      # Config formatting
      nixfmt-rfc-style
    ];
    ${namespace} = {
      bundles.shell = enabled;
      config = {
        apps = enabled;
      };
      misc = {
        # gtk = enabled; # Disabled - conflicts with WhiteSur theme
        # qt = enabled; # Disabled - conflicts with other Qt modules
        scripts = enabled;
      };
      programs = {
        brave = enabled; # Keep as fallback browser
        kitty = enabled;
        lazygit = enabled;
        neovim = enabled;
        tmux = enabled;
      };
    };
  };
}