#!/usr/bin/env python3
"""Generate sops-encrypted cluster Secret manifests from nix-secrets values.

Driven by k8s/secrets-decl.nix (the single source of truth). Each declared
Secret doc becomes its own k8s/secrets/<secret-name>.enc.yaml, encrypted to the
cluster age key (via the repo .sops.yaml creation rule). One Secret per file —
no multi-doc, so sops handling stays simple.

Idempotent: a file is only re-encrypted when its decrypted content actually
changes (sops encryption is non-deterministic, so blind re-encryption would
churn gitops/prod every run).

No plaintext secret ever touches Nix or git — values are pulled from nix-secrets
at generation time and only the ciphertext is written. Uses stdlib + sops only
(sops --output-type json), no third-party python deps.

Run via `just gen-secrets`.
"""
import json
import os
import pathlib
import subprocess
import sys
import tempfile

REPO = pathlib.Path(__file__).resolve().parents[1]
DECL = REPO / "k8s/secrets-decl.nix"
OUT_DIR = REPO / "k8s/secrets"
NIX_SECRETS = (
    pathlib.Path(os.environ.get("NIX_SECRETS_DIR", os.path.expanduser("~/nix-secrets")))
    / "sops/users/starcommand.yaml"
)
USER_AGE_KEY = os.path.expanduser("~/.config/sops/age/keys.txt")
CLUSTER_KEY_PATH = "starcommand/cluster/argocd/sops_age_key"


def sops_json(path, age_key_file):
    """Decrypt a sops file to a python object via JSON output."""
    r = subprocess.run(
        ["sops", "-d", "--output-type", "json", str(path)],
        capture_output=True,
        text=True,
        env={**os.environ, "SOPS_AGE_KEY_FILE": age_key_file},
    )
    return r


def lookup(nsec, slashpath):
    cur = nsec
    for part in slashpath.split("/"):
        cur = cur[part]
    return cur


def resolve(nsec, v):
    if "sops" in v:
        return lookup(nsec, v["sops"])
    if "literal" in v:
        return v["literal"]
    if "template" in v:
        s = v["template"]
        for name, key in (v.get("vars") or {}).items():
            s = s.replace("{" + name + "}", lookup(nsec, key))
        return s
    raise SystemExit(f"bad value spec: {v}")


def build_doc(nsec, doc):
    out = {
        "apiVersion": "v1",
        "kind": "Secret",
        "metadata": {"name": doc["name"], "namespace": doc["namespace"]},
    }
    if doc.get("labels"):
        out["metadata"]["labels"] = doc["labels"]
    if doc.get("type"):
        out["type"] = doc["type"]
    if doc.get("stringData"):
        out["stringData"] = {k: resolve(nsec, v) for k, v in doc["stringData"].items()}
    if doc.get("data"):
        out["data"] = {k: resolve(nsec, v) for k, v in doc["data"].items()}
    return out


def main():
    decl = json.loads(
        subprocess.check_output(["nix", "eval", "--json", "--file", str(DECL)])
    )

    r = sops_json(NIX_SECRETS, USER_AGE_KEY)
    if r.returncode != 0:
        sys.exit(f"cannot decrypt nix-secrets: {r.stderr}")
    nsec = json.loads(r.stdout)

    # combined key (user + cluster) so we can decrypt existing .enc.yaml
    # (encrypted to the cluster key) for the idempotency check
    cluster_key = lookup(nsec, CLUSTER_KEY_PATH)
    with tempfile.NamedTemporaryFile("w", suffix=".txt", delete=False) as f:
        f.write(pathlib.Path(USER_AGE_KEY).read_text() + "\n" + cluster_key + "\n")
        combined_key = f.name

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    changed, unchanged = [], []
    try:
        for _, spec in sorted(decl.items()):
            for d in spec["secrets"]:
                doc = build_doc(nsec, d)
                target = OUT_DIR / f"{doc['metadata']['name']}.enc.yaml"

                if target.exists():
                    cur = sops_json(target, combined_key)
                    if cur.returncode == 0 and json.loads(cur.stdout) == doc:
                        unchanged.append(doc["metadata"]["name"])
                        continue

                target.write_text(json.dumps(doc, indent=2) + "\n")
                enc = subprocess.run(
                    ["sops", "-e", "-i", str(target)],
                    capture_output=True,
                    text=True,
                    env={**os.environ, "SOPS_AGE_KEY_FILE": combined_key},
                )
                if enc.returncode != 0:
                    sys.exit(f"sops encrypt failed for {doc['metadata']['name']}: {enc.stderr}")
                changed.append(doc["metadata"]["name"])
    finally:
        os.unlink(combined_key)

    print(f"encrypted/updated: {', '.join(changed) or '(none)'}")
    print(f"unchanged:         {', '.join(unchanged) or '(none)'}")


if __name__ == "__main__":
    main()
