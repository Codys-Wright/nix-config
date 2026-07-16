# UI enhancements (filetree, statusline, tabline, theme, snacks explorer, etc.)
# Returns config.vim settings directly
# Split by concern into ./ui/*.nix; each part returns a vim-config attrset
# with disjoint attribute paths, merged back into a single attrset here.
{
  lib,
  nvf ? null,
  ...
}@args:
lib.foldl lib.recursiveUpdate { } [
  (import ./ui/appearance.nix args)
  (import ./ui/statusline.nix args)
  (import ./ui/noice.nix args)
  (import ./ui/nvchad.nix args)
]
