# Dwindle Default Layout - Standard balanced splits
# Windows split in half alternating horizontal/vertical
{
  name = "dwindle-default";
  settings = {
    general = {
      layout = "dwindle";
    };
    
    dwindle = {
      pseudotile = false;
      preserve_split = true;
      special_scale_factor = 0.8;
    };
  };
}
