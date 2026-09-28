# Deployable hosts, read from the den host registry — the single source.
#
#   den.hosts.x86_64-linux.nomad.deployment.ip = "192.168.0.139";
#
# Consumed by deploy-rs.nix (deploy.nodes), deployment-packages.nix
# (per-host helper packages) and the justfile (`nix eval .#deployTargets`).
# Reading den.hosts means no NixOS evaluation (and no tryEval hiding
# errors) just to learn where a host lives.
{ config, lib, ... }:
let
  deployTargets = lib.foldl' (
    acc: hosts:
    acc
    // lib.mapAttrs (_: host: {
      inherit (host.deployment) ip sshPort sshUser;
      inherit (host) class system;
    }) (lib.filterAttrs (_: host: host.deployment.enable) hosts)
  ) { } (lib.attrValues config.den.hosts);
in
{
  _module.args.deployTargets = deployTargets;
  flake.deployTargets = deployTargets;
}
