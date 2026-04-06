# Nvf-built Neovim configuration using den aspect composition
# Each _nvf_modules/*.nix is imported as a den sub-aspect via provides.*
# The `vim` class forwards to nvf's config.vim through den.lib.nvf
#
# Based on: https://den.oeiuwq.com/tutorials/nvf-standalone/
{
  inputs,
  lib,
  den,
  fleet,
  ...
}:
let
  # Import helper: call an _nvf_modules file with { lib, nvf }
  importVim =
    path:
    import (./_nvf_modules + "/${path}") {
      inherit lib;
      nvf = inputs.nvf;
    };

  npinsSources = import ../../../npins/default.nix;

  # Build wrapped neovim from the den aspect
  buildWrappedNeovim =
    { pkgs }:
    let
      neovim = den.lib.nvf.package pkgs den.aspects.nvf-config { };
    in
    inputs.wrappers.lib.wrapPackage {
      inherit pkgs;
      package = neovim;
      aliases = [
        "nvf"
        "nv"
        "v"
      ];
      env = {
        NVIM_APPNAME = "nvf";
      };
      runtimeInputs = [
        pkgs.lazygit
        pkgs.gh
        pkgs.git
        pkgs.zellij
        pkgs.vtsls
      ];
    };
in
{
  flake-file.inputs.nvf.url = "github:notashelf/nvf";
  flake-file.inputs.nvf.inputs.nixpkgs.follows = "nixpkgs";
  flake-file.inputs.wrappers.url = "github:lassulus/wrappers";

  # ── NVF vim configuration aspect ──────────────────────────────────────
  # All vim.* settings composed from sub-aspects via provides.*
  den.aspects.nvf-config = {
    includes = with den.aspects.nvf-config.provides; [
      ai
      coding
      debug
      editor
      format
      git
      lang
      lint
      lsp
      nvzone
      snacks
      snacks-picker
      snacks-dashboard
      snacks-git
      snacks-terminal
      test
      ui
      util
      which-key
      plugins
    ];

    # Each provides.* imports an _nvf_modules file as a vim class block
    # ai needs pkgs for sidekick
    provides.ai.vim =
      { pkgs, ... }:
      let
        cfg = importVim "ai.nix";
      in
      cfg
      // {
        extraPlugins = (cfg.extraPlugins or { }) // {
          sidekick = (cfg.extraPlugins.sidekick or { }) // {
            package = pkgs.vimPlugins.sidekick-nvim;
          };
        };
      };

    # coding needs pkgs for grug-far and vim-repeat
    provides.coding.vim =
      { pkgs, ... }:
      let
        cfg = importVim "coding.nix";
      in
      cfg
      // {
        extraPlugins = (cfg.extraPlugins or { }) // {
          grug-far = (cfg.extraPlugins.grug-far or { }) // {
            package = pkgs.vimPlugins.grug-far-nvim;
          };
          vim-repeat = (cfg.extraPlugins.vim-repeat or { }) // {
            package = pkgs.vimPlugins.vim-repeat;
          };
        };
      };
    provides.debug.vim = importVim "debug.nix";
    provides.editor.vim = importVim "editor.nix";
    provides.format.vim = importVim "format.nix";
    provides.git.vim = importVim "git.nix";
    provides.lang.vim = importVim "lang.nix";
    provides.lint.vim = importVim "lint.nix";
    provides.lsp.vim = importVim "lsp.nix";
    # nvzone needs pkgs for floaterm (npins) — merge packages with config
    provides.nvzone.vim =
      { pkgs, ... }:
      let
        nvzoneConfig = importVim "nvzone.nix";
      in
      nvzoneConfig
      // {
        extraPlugins = (nvzoneConfig.extraPlugins or { }) // {
          floaterm = (nvzoneConfig.extraPlugins.floaterm or { }) // {
            package = pkgs.vimUtils.buildVimPlugin {
              pname = "nvzone-floaterm";
              version = builtins.substring 0 8 npinsSources.nvzone-floaterm.revision;
              src = npinsSources.nvzone-floaterm.outPath;
              doCheck = false;
            };
          };
          volt.package = pkgs.vimPlugins.nvzone-volt;
          typr.package = pkgs.vimPlugins.nvzone-typr;
          minty.package = pkgs.vimPlugins.nvzone-minty;
          menu.package = pkgs.vimPlugins.nvzone-menu;
          showkeys.package = pkgs.vimPlugins.showkeys;
          timerly.package = pkgs.vimPlugins.timerly;
        };
      };
    provides.snacks.vim = importVim "snacks/snacks.nix";
    provides.snacks-picker.vim = importVim "snacks/picker.nix";
    provides.snacks-dashboard.vim = importVim "snacks/dashboard.nix";
    provides.snacks-git.vim = importVim "snacks/git.nix";
    provides.snacks-terminal.vim = importVim "snacks/terminal.nix";
    provides.test.vim = importVim "test.nix";
    provides.ui.vim = importVim "ui.nix";
    provides.util.vim = importVim "util.nix";
    provides.which-key.vim = importVim "which-key.nix";

    # Extra plugin packages that need pkgs
    provides.plugins.vim =
      { pkgs, ... }:
      {
        extraPlugins.nvim-treesitter.package = pkgs.vimPlugins.nvim-treesitter;
        extraPlugins.lzn-auto-require.package = pkgs.vimPlugins.lzn-auto-require;
        extraPlugins.friendly-snippets.package = pkgs.vimPlugins.friendly-snippets;
        extraPlugins.vtsls.package = pkgs.vimPlugins.nvim-vtsls;
        extraPlugins.base46 = {
          package = pkgs.vimPlugins.base46;
          setup = ''
            local function load_theme()
              pcall(function()
                local nvconfig = require("nvconfig")
                if nvconfig and nvconfig.base46 then
                  nvconfig.base46.theme = "tokyonight_moon"
                end
              end)
              package.loaded["themes.tokyonight_moon"] = nil
              package.loaded["base46"] = nil
              local base46 = require("base46")
              if base46 and vim.g.base46_cache then
                base46.load_all_highlights()
                return true
              end
              return false
            end
            if not load_theme() then
              vim.defer_fn(load_theme, 10)
            end
          '';
        };
        extraPlugins.nvchad.package = pkgs.vimPlugins.nvchad;
        extraPlugins.nvchad-ui = {
          package = pkgs.vimPlugins.nvchad-ui;
          setup = ''
            require "nvchad"
          '';
        };
      };
  };

  # ── fleet aspect for den host/home composition ──────────────────────────
  fleet.coding._.editors._.nvf = {
    description = "Neovim built with nvf configuration framework";
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          (buildWrappedNeovim { inherit pkgs; })
        ];
      };
  };

  # ── Standalone package and app ────────────────────────────────────────
  perSystem =
    { pkgs, system, ... }:
    let
      pkgsUnfree = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      wrappedNeovim = buildWrappedNeovim { pkgs = pkgsUnfree; };
    in
    {
      packages.nvf = wrappedNeovim;
      apps.nvf = {
        type = "app";
        program = "${wrappedNeovim}/bin/nvim";
      };
    };
}
