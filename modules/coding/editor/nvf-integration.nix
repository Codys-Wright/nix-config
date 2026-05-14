# Den integration for NVF standalone.
# Compose Den `vim` aspects into an nvf module (`vim.*` options) so
# den.lib.nvf.package builds the full configured editor.
{
  den,
  lib,
  inputs,
  ...
}:
{
  den.lib.nvf.package =
    pkgs: vimAspect: ctx:
    (inputs.nvf.lib.neovimConfiguration {
      inherit pkgs;
      modules = [ (den.lib.nvf.module pkgs vimAspect ctx) ];
    }).neovim;

  den.lib.nvf.module =
    pkgs: vimAspect: _ctx:
    let
      # Resolve the source aspect's custom `vim` class directly.  The old
      # implementation used a custom forward from `vim` -> `nvf.vim`, but after
      # Den's fx-forward changes that resolved to an empty nvf module for this
      # standalone-package use case.  nvf's own module system wants the composed
      # vim config under top-level `vim`, so wrap each resolved vim module there.
      vimModule = den.lib.aspects.resolve "vim" vimAspect;

      cleanModule =
        module: if builtins.isAttrs module then builtins.removeAttrs module [ "_file" ] else module;

      wrapVimModule = sourceModule: args: {
        vim = cleanModule (
          if builtins.isFunction sourceModule then sourceModule ({ inherit pkgs; } // args) else sourceModule
        );
      };

      flattenVimModules =
        module:
        if builtins.isAttrs module && module ? imports then
          lib.concatMap flattenVimModules module.imports
        else
          [ (wrapVimModule module) ];
    in
    {
      imports = lib.concatMap flattenVimModules vimModule.imports;
    };
}
