{
  config.vim = {
    # Language support
    languages = {
      enableTreesitter = true;
      nix.enable = true;
      rust.enable = true;
      ts.enable = true;
      markdown.enable = true;
    };

    # LSP support
    lsp.enable = true;

    # Autocomplete
    autocomplete.nvim-cmp.enable = true;

    # Git integration
    mini.git.enable = true;

    # Fuzzy finding
    telescope.enable = true;
    mini.fuzzy.enable = true;

    # Snippets
    mini.snippets.enable = true;
  };
} 