# Dwindle No-Split Layout - Stack windows, minimal splitting
# Windows stack rather than split into smaller tiles
{
  name = "dwindle-no-split";
  settings = {
    general = {
      layout = "dwindle";
    };
    
    dwindle = {
      pseudotile = false;
      preserve_split = false;
      force_split = 2;
      no_gaps_when_only = true;
      special_scale_factor = 0.8;
    };
  };
}
