# Start plugins for the LazyVim utility layer
# Split from ../util.nix — returns config.vim settings directly
{ lib, ... }:
{
  # Add plenary.nvim as a start plugin (common dependency for many Lua plugins)
  startPlugins = [ "plenary-nvim" ];
}
