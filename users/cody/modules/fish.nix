# User-specific fish overrides (if any)
# Most fish configuration is now in FTS.coding._.shells._.fish
{...}: {
  cody.fish.homeManager = {
    ...
  }: {
    programs.fish = {
      # Enable vi key bindings on shell init
      shellInit = ''
        fish_vi_key_bindings
      '';
    };
  };
}
