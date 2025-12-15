# Snacks.nvim dashboard configuration
# Returns config.vim settings directly
# Takes lib as parameter for mkLuaInline
{lib, ...}: {
  # Configure snacks dashboard
  # The dashboard will automatically open on startup when enabled
  utility.snacks-nvim.setupOpts.dashboard = {
    # Enable dashboard (opens automatically on startup)
    enabled = true;

    # Simple dashboard configuration (without startup section since we don't use lazy.nvim)
    sections = lib.generators.mkLuaInline ''
      {
        { section = "header" },
        { section = "keys", gap = 1, padding = 1 },
      }
    '';

    # Customize preset keys to use snacks picker
    preset = lib.generators.mkLuaInline ''
      {
        keys = {
          { icon = "󰈞 ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
          { icon = "󰈔 ", key = "n", desc = "New File", action = ":ene | startinsert" },
          { icon = "󰊄 ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
          { icon = "󰄉 ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
          { icon = "󰒓 ", key = "c", desc = "Config", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
          { icon = "󰦨 ", key = "s", desc = "Restore Session", section = "session" },
          { icon = "󰒲 ", key = "L", desc = "Lazy", action = ":Lazy", enabled = function() return package.loaded.lazy ~= nil end },
          { icon = "󰗼 ", key = "q", desc = "Quit", action = ":qa" },
        },
      }
    '';
  };
}
