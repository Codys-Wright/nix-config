{ config, lib, pkgs, namespace, inputs, ... }:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.coding.editor.nvim;
  nvimPackage = inputs.nvim.packages.${pkgs.system}.${cfg.preset};
in
{
  options.${namespace}.coding.editor.nvim = with types; {
    enable = mkBoolOpt false "Enable Neovim editor";
    preset = mkOption {
      type = types.enum [ "default" "lazy" "minimal" ];
      default = "default";
      description = "Neovim preset to use";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # Add the nvf flake package to home packages
      nvimPackage
    ];

    # Create aliases for the nvim flake
    home.shellAliases = {
      nvim = "exec ${nvimPackage}/bin/nvim";
      nvim-default = "exec ${inputs.nvim.packages.${pkgs.system}.default}/bin/nvim";
      nvim-lazy = "exec ${inputs.nvim.packages.${pkgs.system}.lazy}/bin/nvim";
      nvim-minimal = "exec ${inputs.nvim.packages.${pkgs.system}.minimal}/bin/nvim";
    };

    # Add environment variables for nvim
    home.sessionVariables = {
      EDITOR = "${nvimPackage}/bin/nvim";
      VISUAL = "${nvimPackage}/bin/nvim";
    };
  };
} 