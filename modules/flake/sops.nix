# sops - Secrets management tool
{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.sops = pkgs.sops;
    };
}