{
  config.vim = {
    # Linting with nvim-lint
    diagnostics.nvim-lint = {
      enable = true;
      lint_after_save = true;
      linters_by_ft = {
        fish = [ "fish" ];
        # "*" = [ "typos" ];  # Global linter for all filetypes
        # "_" = [ "fallback" ];  # Fallback linter for unconfigured filetypes
      };
      linters = {
        # Example of conditional linter (commented out)
        # selene = {
        #   condition = "function(ctx) return vim.fs.find({ 'selene.toml' }, { path = ctx.filename, upward = true })[1] end";
        # };
      };
    };
  };
} 