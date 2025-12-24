# Gaming Cursor Preset - Optimized for gaming
# Hardware cursors, no warping for consistent aim
{
  name = "gaming";
  settings = {
    cursor = {
      no_hardware_cursors = false;  # Use hardware cursors for lowest latency
      no_warps = true;               # Don't warp cursor (important for FPS games)
      warp_on_change_workspace = false;
      enable_hyprcursor = true;
    };
  };
}
