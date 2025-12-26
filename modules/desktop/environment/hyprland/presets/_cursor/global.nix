# Global Cursor Settings
# Applied to all cursor presets
{
  name = "global";
  settings = {
    cursor = {
      # Basic cursor settings
      no_hardware_cursors = false;
      no_break_fs_vrr = false;
      min_refresh_rate = 24;
      hotspot_padding = 1;

      # Default cursor behavior
      inactive_timeout = 0;
      hide_on_key_press = false;
      hide_on_touch = true;

      # Default cursor style
      default_monitor = "";
      enable_hyprcursor = true;
    };

    # Input settings that affect cursor
    input = {
      follow_mouse = 1;
      mouse_refocus = true;
      sensitivity = 0.0;
    };
  };
}