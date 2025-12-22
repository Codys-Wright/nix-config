# Language support configuration
# Returns config.vim settings directly
# Takes lib as parameter for consistency (even if not used)
# Based on nvf's default and maximal configurations
{lib, ...}: {
  # Language support
  # Global language options (enable features for all languages)
  languages = {
    # Enable formatting, treesitter, and extra diagnostics globally
    enableFormat = true;
    enableTreesitter = true;
    enableExtraDiagnostics = true;

    # Default languages (always enabled in nvf's default config)
    nix = {
      enable = true;
      # Use nixd LSP (like lazyvim) instead of nil (nvf default)
      lsp = {
        enable = true;
        servers = ["nixd"]; # Use nixd instead of nil (now plural)
      };
      # Formatting with alejandra (nvf default, matches lazyvim)
      format = {
        enable = true;
        type = ["alejandra"]; # alejandra is nvf's default
      };
      # Extra diagnostics (statix and deadnix)
      extraDiagnostics = {
        enable = true;
        types = ["statix" "deadnix"]; # statix and deadnix linters
      };
    };
    markdown.enable = true;

    # Common languages (enabled in nvf's maximal config)
    # Web development
    ts = {
      enable = true; # TypeScript/JavaScript
      # Use ts_ls LSP server
      lsp = {
        enable = true;
        servers = ["ts_ls"];
      };
    };
    html = {
      enable = true;
      # Enable HTML autotag (auto-close/rename HTML/JSX tags) - LazyVim uses nvim-ts-autotag
      treesitter.autotagHtml = true;
    };
    css.enable = true;

    # Systems programming
    rust = {
      enable = true;
      extensions.crates-nvim.enable = true; # Enable rust-tools crates support
    };
    go.enable = true;
    zig.enable = true;
    clang.enable = true; # C/C++

    # Scripting languages
    python.enable = true;
    lua.enable = true;
    bash.enable = true;

    # Other common languages
    sql.enable = true;
    java.enable = true;
    kotlin.enable = true;
    typst.enable = true;

    # Less common languages (disabled by default, enable as needed)
    # assembly.enable = false;
    # astro.enable = false;
    # csharp.enable = false;
    # dart.enable = false;
    # elixir.enable = false;
    # fsharp.enable = false;
    # gleam.enable = false;
    # haskell.enable = false;
    # julia.enable = false;
    # nim.enable = false; # Broken on Darwin
    nu.enable = false;
    # ocaml.enable = false;
    # php.enable = false;
    # r.enable = false;
    # ruby.enable = false;
    # scala.enable = false;
    # svelte.enable = false;
    tailwind.enable = false;
    # vala.enable = false;
    yaml.enable = false;
  };
}
