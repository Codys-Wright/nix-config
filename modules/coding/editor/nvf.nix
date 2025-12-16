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

    # Build the neovim package using nvf.lib.neovimConfiguration
    # Import config files directly - Nix will merge them automatically
    customNeovim = inputs.nvf.lib.neovimConfiguration {
      inherit pkgs;
      modules =
        allModules
        ++ [
          # Pass the nixpkgs packages to the coding module
          {
            config.vim.extraPlugins.grug-far.package = pkgs.vimPlugins.grug-far-nvim;
            config.vim.extraPlugins.vim-repeat.package = pkgs.vimPlugins.vim-repeat;
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

      # Add runtime dependencies for git integration
      # These will be available in PATH when neovim runs
      runtimeInputs = [
        pkgs.lazygit  # Required for Snacks.lazygit integration
        pkgs.gh       # Required for Snacks.gh (GitHub CLI) integration
        pkgs.git      # Required for git operations
      ];

      # Example: Add environment variables
      # env = {
      #   # Set custom config directory
      #   # NVIM_CONFIG_DIR = "/path/to/config";
      #   # Enable debug logging
      #   # NVIM_LOG_FILE = "/tmp/nvim.log";
      # };

      # Example: Add command-line flags that are always passed to neovim
      # flags = {
      #   # Add a startup command
      #   # "--cmd" = "set rtp+=/path/to/plugins";
      #   # Enable headless mode (useful for scripting)
      #   # "--headless" = {};
      # };

      # Example: Add a pre-hook (runs before neovim starts)
      # preHook = ''
      #   # Log startup time
      #   echo "Starting Neovim at $(date)" >&2
      # '';
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
  perSystem = {pkgs, ...}: let
    # Use the shared function to build the wrapped neovim package
    wrappedNeovim = buildWrappedNeovim {inherit pkgs lib;};
  in {
    packages.nvf = wrappedNeovim;

    apps.nvf = {
      type = "app";
      program = "${wrappedNeovim}/bin/nvim";
    };
  };
}
