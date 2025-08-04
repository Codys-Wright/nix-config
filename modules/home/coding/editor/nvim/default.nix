{ config, lib, pkgs, namespace, inputs, ... }:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.coding.editor.nvim;
in
{
  options.${namespace}.coding.editor.nvim = with types; {
    enable = mkBoolOpt false "Enable Neovim editor";
    preset = mkOption {
      type = types.enum [ "default" "lazy" "minimal" ];
      default = "default";
      description = "Neovim preset to use";
    };
    useFlake = mkBoolOpt true "Use the standalone nvim flake instead of system nvim";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # Add the nvim flake package to home packages
      inputs.nvim.packages.${pkgs.system}.${cfg.preset}
    ];

    # Create aliases for the nvim flake
    home.shellAliases = mkIf cfg.useFlake {
      nvim = "exec ${inputs.nvim.packages.${pkgs.system}.${cfg.preset}/bin/nvim";
      nvim-default = "exec ${inputs.nvim.packages.${pkgs.system}.default/bin/nvim";
      nvim-lazy = "exec ${inputs.nvim.packages.${pkgs.system}.lazy/bin/nvim";
      nvim-minimal = "exec ${inputs.nvim.packages.${pkgs.system}.minimal/bin/nvim";
    };

    # Add environment variables for nvim
    home.sessionVariables = mkIf cfg.useFlake {
      EDITOR = "${inputs.nvim.packages.${pkgs.system}.${cfg.preset}/bin/nvim";
      VISUAL = "${inputs.nvim.packages.${pkgs.system}.${cfg.preset}/bin/nvim";
    };
  };
} 