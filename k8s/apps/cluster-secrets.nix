# Cluster secrets — sops-ENCRYPTED k8s Secrets, decrypted at sync by Argo CD's
# repo-server sops CMP (see k8s/apps/argocd.nix). Each file under k8s/secrets/
# is ciphertext (only data/stringData encrypted, to the in-cluster age key); the
# CMP's `discover` glob (**/*.enc.yaml) matches this app's output dir and runs
# `sops -d` on each before apply.
#
# nixidy copies the files VERBATIM via `extraRawYamls` (the top-level sops
# metadata block must survive — a typed parse/emit round-trip would strip it).
#
# These .enc.yaml are produced from nix-secrets values + sops-encrypted to the
# cluster age key (per the repo .sops.yaml creation rule), never hand-edited.
# (Pilot generated them by hand; a nix-driven `gen-secrets` step is the next
# rollout task.) Each Secret carries its own metadata.namespace, so this single
# app spans namespaces (the app `namespace` below is only the default).
{ ... }:
{
  applications.cluster-secrets = {
    namespace = "selfhost";
    createNamespace = false;

    extraRawYamls = [
      ../secrets/pinchflat.enc.yaml
    ];
  };
}
