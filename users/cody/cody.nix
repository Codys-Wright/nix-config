{
  FTS,
  cody,
  ...
}:
{
  den = {
    homes = {
      # Darwin (macOS) home configuration
      aarch64-darwin.cody = {
        userName = "CodyWright";
        aspect = "cody";
      };

      # NixOS home configuration
      x86_64-linux.cody = {
        userName = "cody";
        aspect = "cody";
      };
    };

    # Cody user aspect - includes user-specific configurations
    aspects.cody = {
      description = "Cody user configuration";
      includes = [
        FTS.browsers
        FTS.gaming
        FTS.coding
        FTS.notes
        # FTS.keyboard
        cody.dots
        cody.fish
        cody.admin # Admin privileges and user configuration
        cody.autologin # Autologin configuration (enabled when display manager is present)
        cody.display-session # Default desktop session (gnome)
        (FTS.test {
          hello = true;
          cowsay = true;
        }) # Test module with both packages
        cody.default-shell # Set fish as default shell
      ];
    };

  };

}
