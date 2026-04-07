# Desktop home-manager forwarding bundle
# Include this in provides.to-users to forward all desktop HM config to users.
#
# Usage in host aspect:
#   provides.to-users.includes = [ <fleet.desktop/home> ];
{
  fleet,
  __findFile,
  ...
}:
{
  fleet.desktop._.home = {
    description = "Bundle of all desktop homeManager configs for provides.to-users forwarding";
    includes = [
      <fleet.desktop._.environment._.niri/home>
      <fleet.desktop._.environment._.gnome/home>
      <fleet.desktop._.environment._.kde._.themes._.mactahoe/home>
      <fleet/mactahoe>
    ];
  };
}
