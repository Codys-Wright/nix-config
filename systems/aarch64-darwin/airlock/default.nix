{lib,
pkgs,
namespace,
...
}:
with lib.${namespace};
{
  environment.systemPath = ["/opt/homebrew/bin"];

  system.stateVersion = 4;
}
