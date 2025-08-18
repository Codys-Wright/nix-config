{
  config,
  lib,
  pkgs,
  osConfig,
  namespace,
  inputs,
  ...
}:
with lib;
with lib.${namespace};
{
  snowfallorg.user.enable = true;

}
