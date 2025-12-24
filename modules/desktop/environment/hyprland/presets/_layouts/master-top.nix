# Master Top Layout - Main window on top, stack below
# Good for widescreen monitors, terminal workflows
{
  name = "master-top";
  settings = {
    general = {
      layout = "master";
    };
    
    master = {
      orientation = "top";
      new_status = "master";
      new_on_top = true;
      mfact = 0.60;
      allow_small_split = true;
    };
  };
}
