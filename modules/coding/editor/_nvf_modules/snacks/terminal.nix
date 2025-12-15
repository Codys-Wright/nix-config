# Snacks.nvim terminal configuration
# Returns config.vim settings directly
# Takes lib as parameter for consistency
{lib, ...}: {
  # Configure terminal plugin
  utility.snacks-nvim.setupOpts.terminal = {
    # Terminal navigation keymaps (navigate windows from terminal mode)
    win = {
      keys = {
        nav_h = lib.generators.mkLuaInline ''
          { "<C-h>", function(self)
            return self:is_floating() and "<c-h>" or vim.schedule(function()
              vim.cmd.wincmd("h")
            end)
          end, desc = "Go to Left Window", expr = true, mode = "t" }
        '';
        nav_j = lib.generators.mkLuaInline ''
          { "<C-j>", function(self)
            return self:is_floating() and "<c-j>" or vim.schedule(function()
              vim.cmd.wincmd("j")
            end)
          end, desc = "Go to Lower Window", expr = true, mode = "t" }
        '';
        nav_k = lib.generators.mkLuaInline ''
          { "<C-k>", function(self)
            return self:is_floating() and "<c-k>" or vim.schedule(function()
              vim.cmd.wincmd("k")
            end)
          end, desc = "Go to Upper Window", expr = true, mode = "t" }
        '';
        nav_l = lib.generators.mkLuaInline ''
          { "<C-l>", function(self)
            return self:is_floating() and "<c-l>" or vim.schedule(function()
              vim.cmd.wincmd("l")
            end)
          end, desc = "Go to Right Window", expr = true, mode = "t" }
        '';
      };
    };
  };
}
