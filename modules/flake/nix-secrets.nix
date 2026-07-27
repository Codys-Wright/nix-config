# Private central secrets repo (EmergentMind pattern).
# Soft secrets:  inputs.nix-secrets.<attr>          (plain flake outputs)
# Hard secrets:  "${inputs.nix-secrets}/sops/..."   (sops-encrypted yaml)
#
# ?shallow=1 keeps the constant repinning cheap — the secrets repo accumulates
# rekey commits and we only ever need the latest rev. Fetching happens over
# SSH at evaluation time, so whoever runs nix needs a GitHub-authorized key.
#
# GitHub is the source of truth: `origin` in the ~/nix-secrets checkout points
# at github.com/Codys-Wright/nix-secrets (private), which is the same URL hosts
# evaluate against. Push before `just update-secrets` or hosts repin to a stale
# rev. `codeberg` survives only as a demoted secondary remote.
{ ... }:
{
  flake-file.inputs.nix-secrets.url = "git+ssh://git@github.com/Codys-Wright/nix-secrets.git?ref=main&shallow=1";
}
