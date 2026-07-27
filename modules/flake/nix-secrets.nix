# Private central secrets repo (EmergentMind pattern).
# Soft secrets:  inputs.nix-secrets.<attr>          (plain flake outputs)
# Hard secrets:  "${inputs.nix-secrets}/sops/..."   (sops-encrypted yaml)
#
# ?shallow=1 keeps the constant repinning cheap — the secrets repo accumulates
# rekey commits and we only ever need the latest rev. Fetching happens over
# SSH at evaluation time, so whoever runs nix needs a GitHub-authorized key.
#
# Codeberg (git@codeberg.org:codywright/nix-secrets.git) remains the canonical
# write target — `just edit-secrets` still edits the local ~/nix-secrets
# checkout. GitHub is the read mirror every host evaluates against, so after
# pushing to codeberg also `git push github main` from ~/nix-secrets before
# running `just update-secrets`, or hosts will repin to a stale rev.
{ ... }:
{
  flake-file.inputs.nix-secrets.url = "git+ssh://git@github.com/Codys-Wright/nix-secrets.git?ref=main&shallow=1";
}
