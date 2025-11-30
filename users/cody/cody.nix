{ FTS, cody, ... }:
{
  # Darwin (macOS) home configuration
  den.homes.aarch64-darwin.cody = {
    userName = "CodyWright";
    aspect = "cody";
  };

  # NixOS home configuration
  den.homes.x86_64-linux.cody = {
    userName = "cody";
    aspect = "cody";
  };

  # Cody user aspect - includes user-specific configurations
  den.aspects.cody = {
    description = "Cody user configuration";
    includes = [
      FTS.browsers
      FTS.gaming
      FTS.coding
      cody.dots
      cody.fish
      cody.admin  # Admin privileges and user configuration
      cody.autologin  # Autologin configuration (enabled when display manager is present)
      cody.display-session  # Default desktop session (gnome)
      cody.default-shell  # Set fish as default shell
      cody.oh-my-posh  # Oh My Posh prompt theme
    ];
  };
    
}
