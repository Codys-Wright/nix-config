# Productivity Cursor Preset - Enhanced navigation
# Warp cursor to new workspaces for faster workflow
{
  name = "productivity";
  settings = {
    cursor = {
      no_hardware_cursors = false;
      no_warps = false;
      warp_on_change_workspace = true;  # Warp cursor when switching workspaces
      enable_hyprcursor = true;
      sync_gsettings_theme = true;
    };
  };
}
