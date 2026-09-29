# sops - Secrets management tool
{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  # sops-nix: host (nixos) and home-manager secret decryption, used by
  # hosts/*/sops.nix, modules/config/user-secrets.nix and the cluster agent.
  flake-file.inputs.sops-nix.url = lib.mkDefault "github:Mic92/sops-nix";

  perSystem =
    { pkgs, ... }:
    {
      packages.sops = pkgs.sops;
    };
}
