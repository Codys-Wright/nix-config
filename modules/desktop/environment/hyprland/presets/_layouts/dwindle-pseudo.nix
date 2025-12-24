# Dwindle Pseudotile Layout - Windows maintain aspect ratio
# Good for applications that look better at specific sizes
{
  name = "dwindle-pseudo";
  settings = {
    general = {
      layout = "dwindle";
    };
    
    dwindle = {
      pseudotile = true;
      preserve_split = true;
      force_split = 0;
      special_scale_factor = 0.8;
    };
  };
}
