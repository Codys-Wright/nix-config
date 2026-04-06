# Den integration for NVF standalone
# Provides den.lib.nvf.package and den.lib.nvf.module
# which enable using den aspects to compose NVF configurations
# via a custom `vim` class that forwards to nvf's `vim` config.
#
# Based on: https://den.oeiuwq.com/tutorials/nvf-standalone/
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
      modules = [ (den.lib.nvf.module vimAspect ctx) ];
    }).neovim;

  den.lib.nvf.module =
    vimAspect: ctx:
    let
      # A custom `vim` class that forwards to `nvf.vim`
      vimClass =
        { class, aspect-chain }:
        den._.forward {
          each = lib.singleton true;
          fromClass = _: "vim";
          intoClass = _: "nvf";
          intoPath = _: [ "vim" ];
          fromAspect = _: lib.head aspect-chain;
          adaptArgs = lib.id;
        };

      aspect = den.lib.parametric.fixedTo ctx {
        includes = [
          vimClass
          vimAspect
        ];
      };

      module = den.lib.aspects.resolve "nvf" aspect;
    in
    module;
}
