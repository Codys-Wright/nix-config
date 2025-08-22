{
  config,
  lib,
  pkgs,
  inputs,
  namespace,
  ...
}: let
  inherit (lib) mkIf mkMerge mkOption types;
  cfg = config.${namespace}.coding.editor.nvim;
  presetCfg = cfg.presets.lazyvim;
in {
  config = mkIf (cfg.preset == "lazyvim" && presetCfg.enable) (mkMerge [
    # LazyVim-style configuration using nvf
    {
      programs.neovim = {
        enable = true;
        package = (inputs.nvf.lib.neovimConfiguration {
          inherit pkgs;
          modules = [
            {
              config.vim = {
                viAlias = false;
                vimAlias = true;
                
                # LazyVim-style theme
                theme = {
                  enable = true;
                  name = presetCfg.options.colorscheme;
                  style = "mocha";
                };
                
                # LazyVim-style plugins
                startPlugins = [
                  "lazy-nvim"
                  "nvim-treesitter"
                  "nvim-lspconfig"
                  "nvim-cmp"
                  "telescope-nvim"
                  "which-key-nvim"
                  "lualine-nvim"
                  "bufferline-nvim"
                  "indent-blankline-nvim"
                  "nvim-autopairs"
                  "nvim-ts-autotag"
                  "gitsigns-nvim"
                  "alpha-nvim"
                ];
                
                # LazyVim-style keybindings
                keymaps = [
                  # Leader key
                  {
                    key = "<space>";
                    action = "<nop>";
                    mode = ["n" "v"];
                  }
                  
                  # File operations
                  {
                    key = "<leader>e";
                    action = ":Neotree toggle<CR>";
                    mode = ["n"];
                    desc = "Explorer";
                  }
                  {
                    key = "<leader>w";
                    action = ":w<CR>";
                    mode = ["n"];
                    desc = "Save";
                  }
                  {
                    key = "<leader>q";
                    action = ":q<CR>";
                    mode = ["n"];
                    desc = "Quit";
                  }
                  
                  # Telescope
                  {
                    key = "<leader>ff";
                    action = ":Telescope find_files<CR>";
                    mode = ["n"];
                    desc = "Find Files";
                  }
                  {
                    key = "<leader>fg";
                    action = ":Telescope live_grep<CR>";
                    mode = ["n"];
                    desc = "Grep";
                  }
                  {
                    key = "<leader>fb";
                    action = ":Telescope buffers<CR>";
                    mode = ["n"];
                    desc = "Buffers";
                  }
                  {
                    key = "<leader>fh";
                    action = ":Telescope help_tags<CR>";
                    mode = ["n"];
                    desc = "Help";
                  }
                  
                  # LSP
                  {
                    key = "gd";
                    action = ":lua vim.lsp.buf.definition()<CR>";
                    mode = ["n"];
                    desc = "Go to Definition";
                  }
                  {
                    key = "gr";
                    action = ":lua vim.lsp.buf.references()<CR>";
                    mode = ["n"];
                    desc = "Go to References";
                  }
                  {
                    key = "K";
                    action = ":lua vim.lsp.buf.hover()<CR>";
                    mode = ["n"];
                    desc = "Hover";
                  }
                  {
                    key = "<leader>ca";
                    action = ":lua vim.lsp.buf.code_action()<CR>";
                    mode = ["n"];
                    desc = "Code Action";
                  }
                  {
                    key = "<leader>rn";
                    action = ":lua vim.lsp.buf.rename()<CR>";
                    mode = ["n"];
                    desc = "Rename";
                  }
                  
                  # Buffer navigation
                  {
                    key = "<leader>bn";
                    action = ":bnext<CR>";
                    mode = ["n"];
                    desc = "Next Buffer";
                  }
                  {
                    key = "<leader>bp";
                    action = ":bprevious<CR>";
                    mode = ["n"];
                    desc = "Previous Buffer";
                  }
                  {
                    key = "<leader>bd";
                    action = ":bdelete<CR>";
                    mode = ["n"];
                    desc = "Delete Buffer";
                  }
                  
                  # Window navigation
                  {
                    key = "<C-h>";
                    action = "<C-w>h";
                    mode = ["n"];
                    desc = "Go to left window";
                  }
                  {
                    key = "<C-j>";
                    action = "<C-w>j";
                    mode = ["n"];
                    desc = "Go to lower window";
                  }
                  {
                    key = "<C-k>";
                    action = "<C-w>k";
                    mode = ["n"];
                    desc = "Go to upper window";
                  }
                  {
                    key = "<C-l>";
                    action = "<C-w>l";
                    mode = ["n"];
                    desc = "Go to right window";
                  }
                ];
                
                # LazyVim-style options
                options = {
                  number = true;
                  relativenumber = true;
                  mouse = "a";
                  ignorecase = true;
                  smartcase = true;
                  hlsearch = false;
                  wrap = false;
                  breakindent = true;
                  tabstop = 2;
                  shiftwidth = 2;
                  expandtab = true;
                  signcolumn = "yes";
                  updatetime = 250;
                  timeoutlen = 300;
                  termguicolors = true;
                };
              };
            }
          ];
        }).neovim;
      };

      # Set environment variables
      home.sessionVariables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
      };
    }
  ]);
} 