# LazyVim Neovim configuration
{
  FTS,
  inputs,
  pkgs,
  ...
}:
{
  flake-file.inputs.lazyvim.url = "github:Codys-Wright/lazyvim-nix";

  FTS.coding._.editors._.lazyvim = {
    description = "LazyVim Neovim distribution";

    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          ripgrep
          imagemagick
          tectonic
          ghostscript
          mermaid-cli
          fd
          alejandra
          sqlite
          tree-sitter
          statix
          biome
          nixfmt
          shfmt
          stylua
          typstyle
          terraform
          packer
          oxlint
          sops
        ];
      };

    darwin =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          ripgrep
          imagemagick
          tectonic
          ghostscript
          vscode-js-debug
          mermaid-cli
          fd
          luajitPackages.luarocks-nix
          alejandra
          sqlite
          tree-sitter
          statix
          biome
          nixfmt
          shfmt
          stylua
          typstyle
          terraform
          packer
          oxlint
          sops
        ];
      };

    homeManager =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      let
        # Get the neovim package that lazyvim-nix uses
        neovimPackage = config.programs.neovim.package or pkgs.neovim;

        # Create wrapper script for lazyvim variant
        lazyvimWrapper = pkgs.writeShellApplication {
          name = "lazyvim";
          runtimeEnv = {
            NVIM_APPNAME = "lazyvim";
          };
          runtimeInputs = [ neovimPackage ];
          text = ''exec nvim "$@"'';
        };
      in
      {
        # Import lazyvim Home Manager module to configure lazyvim
        imports = [
          inputs.lazyvim.homeManagerModules.default
        ];

        programs.lazyvim = {
          enable = true;
          pluginSource = "nixpkgs"; # Prefer nixpkgs plugins to avoid luarocks issues
          appName = "lazyvim"; # Install to ~/.config/lazyvim/ instead of ~/.config/nvim/

          # Optionally use existing lazyvim config directory from dots
          # If you want to use your existing config, uncomment this:
          # configFiles = "${config.home.homeDirectory}/.flake/users/cody/dots/config/lazyvim";

          installCoreDependencies = true;

          extras = {
            ai = {
              # avante.enable = true;
              # claudecode.enable = true;
              sidekick.enable = true;
            };
            coding = {
              blink.enable = true;
              mini_snippets.enable = true;
              mini_surround.enable = true;
              yanky.enable = true;
            };
            editor = {
              aerial.enable = true;
              dial.enable = true;
              harpoon2.enable = true;
              illuminate.enable = true;
              inc_rename.enable = true;
              mini_diff.enable = true;
              mini_files.enable = true;
              overseer.enable = true;
              refactoring.enable = true;
            };
            formatting = {
              biome.enable = true;
              prettier.enable = true;
            };
            lang = {
              nix.enable = true;
              rust = {
                enable = true;
                installDependencies = true;
                installRuntimeDependencies = false;
              };
              typescript = {
                enable = true;
                installDependencies = true;
                installRuntimeDependencies = true;
              };

              tailwind.enable = true;
              typst.enable = true;
              nushell.enable = true;
              git.enable = true;
              cmake.enable = true;
              docker.enable = true;
              # sql.enable = true;
              terraform.enable = true;
              tex.enable = true;
              toml.enable = true;
              json.enable = true;
              yaml.enable = true;
              zig.enable = true;
            };
            linting = {
              eslint.enable = true;
              none_ls.enable = true;
            };
            test = {
              core.enable = true;
            };
            ui = {
              treesitter_context.enable = true;
            };
            util = {
              gh.enable = true;
              project.enable = true;
              mini_hipatterns.enable = true;
              rest.enable = true;
            };
          };

          # Additional packages (optional)
          extraPackages = with pkgs; [
            tree-sitter
            nixd # Nix LSP
            alejandra # Nix formatter
            bacon # rust background checker
            ripgrep
            jq # For JSON formatting in rest-nvim
            sqlite
            lsof
            html-tidy # For HTML formatting in rest-nvim
            luajitPackages.luarocks-nix # Lua package manager for rest-nvim
            lua54Packages.luarocks-nix # Lua package manager for rest-nvim
            luajitPackages.luarocks
            luajitPackages.luarocks_bootstrap
            luajitPackages.xml2lua # Lua package for XML to Lua conversion
            luajitPackages.mimetypes # Lua package for MIME type detection
            websocat
            grpcurl
            sops # SOPS encryption tool for nvim-sops
          ];

          # Tree-sitter parsers (nix and rust are auto-installed via lang extras)
          # python is auto-installed (core parser)
          treesitterParsers = with pkgs.tree-sitter-grammars; [
            tree-sitter-css
            tree-sitter-latex
            tree-sitter-scss
            tree-sitter-svelte
            tree-sitter-typst
            tree-sitter-vue
          ];

          # Custom plugin configurations
          # Each key becomes a file lua/plugins/{key}.lua
          plugins = {
            fidget-nvim = ''
              return {
                {
                  -- Use nixpkgs version via dir option to avoid fetching from GitHub
                  dir = "${pkgs.vimPlugins.fidget-nvim}",
                  name = "fidget-nvim",
                  config = function()
                    require("fidget").setup({
                    -- Options related to LSP progress subsystem
                    progress = {
                      poll_rate = 0,
                      suppress_on_insert = false,
                      ignore_done_already = false,
                      ignore_empty_message = false,
                      clear_on_detach = function(client_id)
                        local client = vim.lsp.get_client_by_id(client_id)
                        return client and client.name or nil
                      end,
                      notification_group = function(msg) return msg.lsp_client.name end,
                      ignore = {},
                      display = {
                        render_limit = 16,
                        done_ttl = 3,
                        done_icon = "✔",
                        done_style = "Constant",
                        progress_ttl = math.huge,
                        progress_icon = { "dots" },
                        progress_style = "WarningMsg",
                        group_style = "Title",
                        icon_style = "Question",
                        priority = 30,
                        skip_history = true,
                        format_message = require("fidget.progress.display").default_format_message,
                        format_annote = function(msg) return msg.title end,
                        format_group_name = function(group) return tostring(group) end,
                        overrides = {
                          rust_analyzer = { name = "rust-analyzer" },
                        },
                      },
                      lsp = {
                        progress_ringbuf_size = 0,
                        log_handler = false,
                      },
                    },
                    -- Options related to notification subsystem
                    notification = {
                      poll_rate = 10,
                      filter = vim.log.levels.INFO,
                      history_size = 128,
                      override_vim_notify = false,
                      configs = { default = require("fidget.notification").default_config },
                      redirect = function(msg, level, opts)
                        if opts and opts.on_open then
                          return require("fidget.integration.nvim-notify").delegate(msg, level, opts)
                        end
                      end,
                      view = {
                        stack_upwards = true,
                        align = "message",
                        reflow = false,
                        icon_separator = " ",
                        group_separator = "---",
                        group_separator_hl = "Comment",
                        line_margin = 1,
                        render_message = function(msg, cnt)
                          return cnt == 1 and msg or string.format("(%dx) %s", cnt, msg)
                        end,
                      },
                      window = {
                        normal_hl = "Comment",
                        winblend = 100,
                        border = "none",
                        zindex = 45,
                        max_width = 0,
                        max_height = 0,
                        x_padding = 1,
                        y_padding = 0,
                        align = "bottom",
                        relative = "editor",
                        tabstop = 8,
                        avoid = {},
                      },
                    },
                    -- Options related to integrating with other plugins
                    integration = {
                      ["nvim-tree"] = {
                        enable = true,
                      },
                      ["xcodebuild-nvim"] = {
                        enable = true,
                      },
                    },
                    -- Options related to logging
                    logger = {
                      level = vim.log.levels.WARN,
                      max_size = 10000,
                      float_precision = 0.01,
                      path = string.format("%s/fidget.nvim.log", vim.fn.stdpath("cache")),
                    },
                    })
                  end,
                },
              }
            '';

            nvim-sops = ''
              return {
                {
                  "lucidph3nx/nvim-sops",
                  event = { "BufEnter" },
                  opts = {
                    enabled = true,
                    debug = false,
                    binPath = "sops",
                    defaults = {
                      awsProfile = "AWS_PROFILE",
                      ageKeyFile = "SOPS_AGE_KEY_FILE",
                      gcpCredentialsPath = "GOOGLE_APPLICATION_CREDENTIALS",
                    },
                  },
                  keys = {
                    { "<leader>dsd", vim.cmd.SopsDecrypt, desc = "[S]ops [D]ecrypt" },
                    { "<leader>dse", vim.cmd.SopsEncrypt, desc = "[S]ops [E]ncrypt" },
                  },
                },
              }
            '';
          };
        };

        # Install the lazyvim wrapper executable
        home.packages = [ lazyvimWrapper ];
      };
  };
}
