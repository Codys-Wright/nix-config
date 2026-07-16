# Editor enhancements (aerial, dial, harpoon, etc.)
# Returns config.vim settings directly
# Split by concern into ./editor/*.nix; each part returns a vim-config attrset
# with disjoint attribute paths, merged back into a single attrset here.
{ lib, ... }@args:
lib.foldl lib.recursiveUpdate { } [
  (import ./editor/options.nix args)
  (import ./editor/keymaps.nix args)
  (import ./editor/plugins.nix args)
  (import ./editor/autocmds.nix args)
]
