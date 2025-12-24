# Default Workspace Rules - Template for workspace configuration
# Workflows can extend this with monitor-specific assignments
{
  name = "default";
  settings = {
    workspace = [
      # Special workspace with scratchpad terminal
      "special:scratchpad, on-created-empty:kitty"
      
      # Workflows should add monitor assignments in their settings block
      # Example:
      # workspace = [
      #   "1, monitor:DP-4, default:true"
      #   "2, monitor:DP-4"
      #   "5, monitor:DP-5"
      # ];
    ];
  };
}
