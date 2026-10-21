"""Mint a GitHub App installation token for Hermes's bots.

    github-app-token [APP] [--owner OWNER]   print a token (cached until ~5 min before expiry)
    github-app-token --git-credential [APP]  git credential-helper output for `get`

APP (default fts-forge) is a directory holding private-key.pem and app-id,
looked up in order: $GITHUB_APPS_DIR/APP, ~/.config/github-apps/APP,
/data/.config/github-apps/APP (the Hermes pod's seed, shared by every profile
HOME). $GITHUB_APP_KEY_FILE ("{app}" expands to APP), when readable, is used
instead (fleet hosts: sops-nix's /run/secrets/github-apps/APP.pem). A missing
app-id file falls back to $GITHUB_APP_ID.

OWNER picks the installation (a user or org login); default: the only/first
installation. With --git-credential and no --owner, the owner comes from the
request path (set credential.useHttpPath); an owner the app is not installed
on falls back to the default installation.

Never prints the key; the token goes to stdout only (that is the interface).
"""
import argparse
import calendar
import json
import os
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

import jwt

API = "https://api.github.com"


class NoInstallation(Exception):
    pass


def _req(url, token, method="GET"):
    req = urllib.request.Request(url, method=method, headers={
        "Authorization": f"Bearer {token}",
        "Accept": "application/vnd.github+json",
        "User-Agent": "hermes-github-app-token",
    })
    with urllib.request.urlopen(req, timeout=20) as resp:
        return json.load(resp)


def _app_dir(app: str) -> Path:
    # A single key file wins (fleet hosts: sops-nix decrypts it to
    # /run/secrets/github-apps/<app>.pem, readable by the agent user only).
    kf = os.environ.get("GITHUB_APP_KEY_FILE", "").replace("{app}", app)
    if kf and os.access(kf, os.R_OK):
        return Path(kf)
    cands = []
    if os.environ.get("GITHUB_APPS_DIR"):
        cands.append(Path(os.environ["GITHUB_APPS_DIR"]) / app)
    if os.environ.get("HOME"):
        cands.append(Path(os.environ["HOME"]) / ".config" / "github-apps" / app)
    cands += [Path("/data/.config/github-apps") / app]
    for c in cands:
        if os.access(c / "private-key.pem", os.R_OK):
            return c
    sys.exit(f"github-app-token: no readable private-key.pem for {app} (looked in {', '.join(map(str, cands))})")


def _cache(app: str, owner: str | None) -> Path:
    # Per-uid name: on a shared /tmp another user's cache file is unreadable
    # (0600) and must not make this user's write fail.
    d = os.environ.get("XDG_RUNTIME_DIR") or "/tmp"
    return Path(d) / f"github-app-{os.getuid()}-{app}-{(owner or '_').lower()}.json"


def token(app: str, owner: str | None) -> str:
    cache = _cache(app, owner)
    try:
        c = json.loads(cache.read_text())
        if c["expires"] - time.time() > 300:
            return c["token"]
    except Exception:
        pass
    base = _app_dir(app)
    if base.is_file():  # $GITHUB_APP_KEY_FILE
        key = base.read_text()
        app_id = os.environ.get("GITHUB_APP_ID", "").strip()
    else:
        key = (base / "private-key.pem").read_text()
        try:
            app_id = (base / "app-id").read_text().strip()
        except OSError:
            app_id = os.environ.get("GITHUB_APP_ID", "").strip()
    if not app_id:
        sys.exit(f"github-app-token: no app-id for {app} (file {base}/app-id or $GITHUB_APP_ID)")
    now = int(time.time())
    app_jwt = jwt.encode({"iat": now - 60, "exp": now + 540, "iss": app_id}, key, algorithm="RS256")
    installs = _req(f"{API}/app/installations", app_jwt)
    if owner:
        installs = [i for i in installs if i["account"]["login"].lower() == owner.lower()]
    if not installs:
        raise NoInstallation(f"github-app-token: {app} has no installation{' for ' + owner if owner else ''}")
    t = _req(f"{API}/app/installations/{installs[0]['id']}/access_tokens", app_jwt, method="POST")
    expires = calendar.timegm(time.strptime(t["expires_at"], "%Y-%m-%dT%H:%M:%SZ"))
    old = os.umask(0o077)
    try:
        tmp = cache.with_suffix(f".{os.getpid()}.tmp")
        tmp.write_text(json.dumps({"token": t["token"], "expires": expires}))
        os.replace(tmp, cache)
    except OSError:
        pass  # caching is best-effort
    finally:
        os.umask(old)
    return t["token"]


def token_or_default(app: str, owner: str | None) -> str:
    """Token for owner's installation, else the app's default installation."""
    try:
        return token(app, owner)
    except NoInstallation:
        if not owner:
            raise
        return token(app, None)


def main() -> None:
    ap = argparse.ArgumentParser(prog="github-app-token")
    ap.add_argument("app", nargs="?", default="fts-forge")
    ap.add_argument("--owner")
    ap.add_argument("--git-credential", action="store_true")
    ap.add_argument("--fallback", action="store_true",
                    help="if OWNER has no installation, use the default one")
    ap.add_argument("op", nargs="?", help=argparse.SUPPRESS)
    a, rest = ap.parse_known_args()
    try:
        if a.git_credential:
            # git calls `<helper> get|store|erase`; answer `get` only, for github.com.
            op = rest[-1] if rest else (a.op or "get")
            if op != "get":
                return
            req = dict(l.split("=", 1) for l in sys.stdin.read().splitlines() if "=" in l)
            if req.get("host") != "github.com":
                return
            owner = a.owner
            if not owner and req.get("path"):
                owner = req["path"].lstrip("/").split("/", 1)[0] or None
            print("username=x-access-token")
            print(f"password={token_or_default(a.app, owner)}")
            return
        print(token_or_default(a.app, a.owner) if a.fallback else token(a.app, a.owner))
    except NoInstallation as e:
        sys.exit(str(e))
    except urllib.error.URLError as e:
        sys.exit(f"github-app-token: GitHub API error: {e}")


if __name__ == "__main__":
    main()
