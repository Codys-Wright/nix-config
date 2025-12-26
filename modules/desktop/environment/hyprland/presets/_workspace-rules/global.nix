# Global Workspace Rules
# Applied to all workspace-rules presets
{
  name = "global";
  settings = {
    # Basic workspace behavior rules
    workspace = [
      # Special workspace rules
      "special, gapsin:0, gapsout:0, border:false"

      # Floating workspace rules
      "f[1], gapsin:0, gapsout:0, border:false"
    ];
  };
}