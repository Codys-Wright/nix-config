# Private central secrets repo (EmergentMind pattern).
# Soft secrets:  inputs.nix-secrets.<attr>          (plain flake outputs)
# Hard secrets:  "${inputs.nix-secrets}/sops/..."   (sops-encrypted yaml)
#
# ?shallow=1 keeps the constant repinning cheap — the secrets repo accumulates
# rekey commits and we only ever need the latest rev. Fetching happens over
# SSH at evaluation time, so whoever runs nix needs a Codeberg-authorized key.
{ ... }:
{
  flake-file.inputs.nix-secrets.url = "git+ssh://git@codeberg.org/codywright/nix-secrets.git?ref=main&shallow=1";
}
