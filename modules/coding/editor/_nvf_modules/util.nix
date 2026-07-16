# LazyVim utility functions ported to nvf
# Returns config.vim settings directly
# Split into ./util/*.nix; the luaConfigPre fragments are concatenated here in
# the original order (core -> root -> lualine/commands/format/cmp) so the
# resulting string is byte-identical to the pre-split file.
{ lib, ... }@args:
(import ./util/plugins.nix args)
// {
  luaConfigPre =
    (import ./util/lazyvim-core.nix args).luaConfigPre
    + (import ./util/lazyvim-root.nix args).luaConfigPre
    + (import ./util/lazyvim-lualine.nix args).luaConfigPre;
}
