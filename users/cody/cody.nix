{
  FTS,
  cody,
  __findFile,
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
        # User-level theme (context-aware: only affects homeManager appearance)
        (<FTS.theme> { default = "cody"; })

        # Applications - all included by default
        <FTS.apps/browsers>
        <FTS.apps/gaming>
        <FTS.apps/notes>
        <FTS.apps/misc>

        # Coding environment - all tools included by default
        <FTS.coding/cli>
        <FTS.coding/editors>
        <FTS.coding/terminals>
        <FTS.coding/shells>
        <FTS.coding/lang>
        <FTS.coding/tools>
        # User configuration
        <FTS.user/admin> # Admin privileges and user configuration
        <FTS.user/autologin> # Autologin configuration (enabled when display manager is present)
        (<FTS.user/shell> { default = "fish"; }) # Set fish as default shell

        # Cody-specific configurations
        cody.dots
        cody.fish
      ];
    };

  };

}
