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

 home.stateVersion = "24.05";
}
