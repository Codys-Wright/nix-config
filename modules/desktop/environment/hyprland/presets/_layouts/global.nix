# Global Layout Settings
# Applied to all layout presets
{
  name = "global";
  settings = {
    # Default dwindle layout settings
    dwindle = {
      pseudotile = true;
      preserve_split = true;
      special_scale_factor = 0.8;
      split_width_multiplier = 1.0;
      use_active_for_splits = true;
      force_split = 0;
    };

    # Default master layout settings
    master = {
      new_status = "slave";
      allow_small_split = true;
      mfact = 0.5;
      orientation = "left";
      special_scale_factor = 0.8;
      new_on_top = false;
      inherit_fullscreen = true;
    };

    # Default general layout settings
    general = {
      layout = "dwindle";
      gaps_in = 5;
      gaps_out = 10;
      border_size = 2;
      no_border_on_floating = false;
      no_focus_fallback = false;
      resize_on_border = true;
      extend_border_grab_area = 15;
      hover_icon_on_border = true;
    };
  };
}