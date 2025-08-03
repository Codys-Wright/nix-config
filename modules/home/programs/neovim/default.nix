{
  config,
  pkgs,
  lib,
  namespace,
  inputs,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.programs.neovim;
in
{
  options.${namespace}.programs.neovim = {
    enable = mkBoolOpt false "${namespace}.programs.neovim.enable";
  };
  config = mkIf cfg.enable {
    # Disabled - using system neovim instead
    # programs.neovim = {
    #   enable = true;
    #   defaultEditor = true;
    #   viAlias = true;
    #   vimAlias = true;
    #   package = inputs.nvim.packages.${pkgs.system}.default;
    #   extraPackages = with pkgs; [ ... ];
    # };
  };
}
