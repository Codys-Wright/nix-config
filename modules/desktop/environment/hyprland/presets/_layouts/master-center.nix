# Master Center Layout - Main window centered, stacks on sides
# Good for focusing on primary window
{
  name = "master-center";
  settings = {
    general = {
      layout = "master";
    };
    
    master = {
      orientation = "center";
      new_status = "master";
      new_on_top = true;
      mfact = 0.50;
      allow_small_split = true;
    };
  };
}
