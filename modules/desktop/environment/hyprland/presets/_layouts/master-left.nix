# Master Left Layout - Main window on left, stack on right
# Good for main app + multiple reference windows
{
  name = "master-left";
  settings = {
    general = {
      layout = "master";
    };
    
    master = {
      orientation = "left";
      new_status = "master";
      new_on_top = true;
      mfact = 0.55;
      allow_small_split = true;
    };
  };
}
