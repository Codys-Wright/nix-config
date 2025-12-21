# Nvf-built Neovim configuration
{
  inputs,
  lib,
  ...
}: let
  # Helper function to import nvf modules from a list of names
  # All modules receive lib as a parameter (even if they don't use it)
  # This keeps the pattern consistent and allows modules to use lib when needed
  # Supports both:
  #   - "snacks" -> checks for snacks/snacks.nix, falls back to snacks.nix
  #   - "snacks/picker" -> directly imports snacks/picker.nix
  importNvfModules = {
    moduleNames,
    lib,
  }:
    map (name: let
      # Check if name contains a slash (nested path like "snacks/picker")
      hasSlash = lib.hasInfix "/" name;

      # If it has a slash, use it directly (e.g., "snacks/picker" -> "snacks/picker.nix")
      # Otherwise, check for nested directory structure
      filePath =
        if hasSlash
        then "${name}.nix"
        else let
          # Check if nested file exists (directory with same name)
          nestedPath = ./_nvf_modules + "/${name}/${name}.nix";
          nestedExists = builtins.tryEval (builtins.pathExists nestedPath);
        in
          if nestedExists.success && nestedExists.value
          then "${name}/${name}.nix"
          else "${name}.nix";
    in {
      config.vim = import (./_nvf_modules + "/${filePath}") {
        inherit lib;
        nvf = inputs.nvf; # Pass nvf for DAG functions (optional in modules)
      };
    })
    moduleNames;

  # List of all nvf module names - single source of truth
  # All modules receive lib as a parameter for consistency
  # Use "snacks/picker" format for nested modules
  # Comment out modules to disable them for debugging
  nvfModuleNames = [
    "ai"
    "coding"
    "debug" # TEMPORARILY DISABLED to test x key timeout
    "editor"
    "format"
    "git"
    "lang"
    "lint"
    "lsp"
    "nvzone"
    "snacks"
    "snacks/picker"
    "snacks/dashboard"
    "snacks/git"
    "snacks/terminal"
    "test"
    "ui"
    "util"
    "which-key"
  ];

  # Common function to build the wrapped neovim package
  # This eliminates duplication between perSystem and homeManager
  buildWrappedNeovim = {
    pkgs,
    lib,
  }: let
    # Import all modules using the helper function (all get lib)
    # Nix will automatically merge all keymaps and configs
    allModules = importNvfModules {
      moduleNames = nvfModuleNames;
      inherit lib;
    };

    # Import npins sources for building floaterm
    # Path: from modules/coding/editor/nvf.nix to root npins/default.nix
    # npins/default.nix returns a set directly, not a function
    npinsSources = import ../../../npins/default.nix;

    # Build the neovim package using nvf.lib.neovimConfiguration
    # Import config files directly - Nix will merge them automatically
    customNeovim = inputs.nvf.lib.neovimConfiguration {
      inherit pkgs;
      modules =
        allModules
        ++ [
          # Pass the nixpkgs packages to various modules
          {
            config.vim.extraPlugins.grug-far.package = pkgs.vimPlugins.grug-far-nvim;
            config.vim.extraPlugins.vim-repeat.package = pkgs.vimPlugins.vim-repeat;
            # Build floaterm from npins sources (not in nixpkgs yet)
            # Disable require check because it depends on volt which isn't available during check
            config.vim.extraPlugins.floaterm.package = pkgs.vimUtils.buildVimPlugin {
              pname = "nvzone-floaterm";
              version = builtins.substring 0 8 npinsSources.nvzone-floaterm.revision;
              src = npinsSources.nvzone-floaterm.outPath;
              doCheck = false; # Disable require check - depends on volt
            };
            # nvzone plugins from nixpkgs
            config.vim.extraPlugins.volt.package = pkgs.vimPlugins.nvzone-volt;
            config.vim.extraPlugins.typr.package = pkgs.vimPlugins.nvzone-typr;
            config.vim.extraPlugins.minty.package = pkgs.vimPlugins.nvzone-minty;
            config.vim.extraPlugins.menu.package = pkgs.vimPlugins.nvzone-menu;
            config.vim.extraPlugins.showkeys.package = pkgs.vimPlugins.showkeys;
            config.vim.extraPlugins.timerly.package = pkgs.vimPlugins.timerly;
            # sidekick (Sidekick for next edit suggestions)
            config.vim.extraPlugins.sidekick.package = pkgs.vimPlugins.sidekick-nvim;
            # lzn-auto-require (required by nvchad-ui for optional module loading)
            config.vim.extraPlugins.lzn-auto-require.package = pkgs.vimPlugins.lzn-auto-require;
            # friendly-snippets (snippet collection for mini.snippets and blink.cmp)
            config.vim.extraPlugins.friendly-snippets.package = pkgs.vimPlugins.friendly-snippets;
            # Base46 theming plugin (required by nvchad-ui)
            # Setup function loads theme immediately when base46 loads (before UI renders)
            # This prevents flash of wrong theme on startup
            # Note: chadrc should be configured before this runs (via luaConfigRC.nvchad-ui-config)
            config.vim.extraPlugins.base46 = {
              package = pkgs.vimPlugins.base46;
              setup = ''
                -- Load base46 theme immediately when base46 loads (before UI renders)
                -- This prevents flash of wrong theme on startup
                -- Ensure chadrc/nvconfig is available (should be set up in luaConfigRC)
                local function load_theme()
                  -- Programmatically set the theme in nvconfig before base46 reads it
                  pcall(function()
                    local nvconfig = require("nvconfig")
                    if nvconfig and nvconfig.base46 then
                      nvconfig.base46.theme = "tokyonight_moon"
                    end
                  end)

                  -- Clear cached theme module AND base46 module so base46 can find our custom theme
                  -- This ensures polish_hl overrides are loaded fresh
                  package.loaded["themes.tokyonight_moon"] = nil
                  package.loaded["base46"] = nil

                  -- Load base46 and compile/load highlights
                  local base46 = require("base46")
                  if base46 and vim.g.base46_cache then
                    -- Force reload by clearing cache and recompiling
                    base46.load_all_highlights()
                    return true
                  end
                  return false
                end

                -- Try to load immediately
                if not load_theme() then
                  -- If chadrc isn't ready yet, wait a tiny bit
                  vim.defer_fn(load_theme, 10)
                end
              '';
            };
            # NvChad base plugin (provides core functionality)
            config.vim.extraPlugins.nvchad.package = pkgs.vimPlugins.nvchad;
            # NvChad UI plugin (provides cheatsheet, statusline, tabufline, etc.)
            # Requires lzn-auto-require, base46 and nvchad base
            # Setup function must call require "nvchad" to initialize commands
            config.vim.extraPlugins.nvchad-ui = {
              package = pkgs.vimPlugins.nvchad-ui;
              setup = ''
                -- Initialize nvchad (this sets up commands like NvCheatsheet, Nvdash, etc.)
                require "nvchad"
              '';
            };
          }
        ];
    };

    # Wrap the neovim package using wrappers library
    # This allows us to add runtime dependencies, environment variables, flags, etc.
    # The wrapper preserves all outputs from the original package (man pages, completions, etc.)
    wrappedNeovim = inputs.wrappers.lib.wrapPackage {
      inherit pkgs;
      package = customNeovim.neovim;

      # Add aliases so you can call it as 'nvf', 'nv', or 'v'
      aliases = ["nvf" "nv" "v"];

      # Set NVIM_APPNAME so Neovim uses the appname-specific config directory
      # This makes Neovim look for config at ~/.config/nvf instead of ~/.config/nvim
      # We don't set XDG_CONFIG_HOME because that would break other applications (like fish)
      # Instead, we use additionalRuntimePaths in ui.nix to add the themes directory
      # base46 will find themes via require("themes.tokyonight_moon") which searches runtimepath
      env = {
        NVIM_APPNAME = "nvf";
      };

      # Add runtime dependencies for git integration
      # These will be available in PATH when neovim runs
      runtimeInputs = [
        pkgs.lazygit # Required for Snacks.lazygit integration
        pkgs.gh # Required for Snacks.gh (GitHub CLI) integration
        pkgs.git # Required for git operations
        pkgs.zellij # Required for sidekick.nvim CLI mux backend
      ];
    };
  in
    wrappedNeovim;
in {
  flake-file.inputs.nvf.url = "github:notashelf/nvf";
  flake-file.inputs.nvf.inputs.nixpkgs.follows = "nixpkgs";
  flake-file.inputs.wrappers.url = "github:lassulus/wrappers";

  FTS.coding._.editors._.nvf = {
    description = "Neovim built with nvf configuration framework";

    # Home Manager integration - expose wrapped nvf as a package
    homeManager = {
      pkgs,
      lib,
      ...
    }: {
      home.packages = [
        (buildWrappedNeovim {inherit pkgs lib;})
      ];
    };
  };

  # Expose nvf as a standalone wrapped package using nvf.lib.neovimConfiguration
  # This builds the configuration from all sub-modules and wraps it
  # Usage: nix run .#nvf or nix build .#nvf
  perSystem = {pkgs, system, ...}: let
    # Import nixpkgs with allowUnfree enabled for sidekick and other unfree packages
    # Use inputs from module scope (not perSystem parameters)
    pkgsUnfree = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
    # Use the shared function to build the wrapped neovim package with unfree-enabled pkgs
    wrappedNeovim = buildWrappedNeovim {pkgs = pkgsUnfree; inherit lib;};
  in {
    packages.nvf = wrappedNeovim;

    apps.nvf = {
      type = "app";
      program = "${wrappedNeovim}/bin/nvim";
    };
  };
}
