{
  lib,
  pkgs,
  inputs,
  ...
}:
let
  # Get the nvim package from the standalone flake
  nvim-package = inputs.nvim.packages.${pkgs.system}.default;
in
nvim-package 