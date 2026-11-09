"""fleet-t3: start, read, steer and watch T3 Code threads on other fleet machines.

Every fleet machine runs its own T3 Code server, whose MCP endpoint (/mcp,
Streamable HTTP, tailnet-only through Tailscale Serve) only reaches that
machine's threads. fleet-t3 holds one bearer token per host and exposes the
useful thread tools with a `host` argument, as a stdio MCP server (`fleet-t3
mcp`) and as a CLI.

Tokens are mutable per-machine state in $XDG_STATE_HOME/fleet-t3/tokens
(0600), never in nix-secrets. `fleet-t3 pair HOST` runs T3's own MCP OAuth
flow and approves it the way the consent page does when you type a pairing
code: the one-time code is minted on HOST over SSH (`t3 auth pairing create`,
5 minutes, only the scopes a full-access client gets). So SSH access is the
root of trust, nobody clicks anything, and `fleet-t3 renew` (a daily timer)
replaces each 30-day token before it expires and revokes the old sessions.
Full access matters: T3 refuses to launch, message or interrupt a thread
whose mode is broader than the client's ceiling. `fleet-t3 pair HOST --oauth`
is the browser-consent fallback for a host this machine can't SSH into.

`thread_watch` starts a detached watcher that waits on the remote thread and,
when it stops, sends a message to the caller's own T3 thread, which wakes the
calling agent. No agent polls.

Never prints a token. Config: $FLEET_T3_CONFIG or ~/.config/fleet-t3/hosts.json.
"""

import base64
import hashlib
import http.server
import json
import os
import secrets
import shlex
import shutil
import signal
import socket
import subprocess
import sys
import threading
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timedelta, timezone

VERSION = "0.1.0"
SCOPES = ["orchestration:read", "orchestration:operate"]
# What T3 grants an MCP client approved at full-access (mcpClientScopes); the
# one-time pairing code that approves it needs exactly these.
FULL_ACCESS_SCOPES = SCOPES + ["settings:write", "source-control:write"]
# T3 issues MCP client tokens for 30 days; renew with a week and a half to spare.
RENEW_BEFORE = timedelta(days=10)
WARN_BEFORE = timedelta(days=7)
# Statuses a thread passes through while a run is in flight.
ACTIVE = {"preparing", "queued", "starting", "running", "waiting"}
TERMINAL = {"completed", "interrupted", "failed", "cancelled", "rolled_back"}
WAIT_CHUNK_S = 240  # one remote t3_thread_wait call; keeps HTTP requests short of proxy limits
MAX_WAIT_S = 45 * 60


class Fail(Exception):
    """An error whose message is safe to show (never contains a token)."""


class AuthFail(Fail):
    pass


class Unreachable(Fail):
    pass


# ---------------------------------------------------------------- config/state


def now():
    return datetime.now(timezone.utc)


def parse_ts(s):
    return datetime.fromisoformat(s.replace("Z", "+00:00")) if s else None


def config_path():
    return os.environ.get("FLEET_T3_CONFIG") or os.path.expanduser("~/.config/fleet-t3/hosts.json")


def load_config():
    p = config_path()
    try:
        with open(p) as f:
            cfg = json.load(f)
    except FileNotFoundError:
        raise Fail(f"no fleet-t3 config at {p}")
    cfg.setdefault("hosts", {})
    cfg["self"] = cfg.get("self") or socket.gethostname().split(".")[0].lower()
    return cfg


def state_dir(*parts):
    base = os.environ.get("XDG_STATE_HOME") or os.path.expanduser("~/.local/state")
    d = os.path.join(base, "fleet-t3", *parts)
    os.makedirs(d, mode=0o700, exist_ok=True)
    return d


def write_private(path, data):
    tmp = f"{path}.tmp{os.getpid()}"
    fd = os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w") as f:
        f.write(data)
    os.replace(tmp, path)


def host_entry(cfg, host):
    host = (host or "").lower()
    if host in ("self", "local", "here", ""):
        host = cfg["self"]
    if host not in cfg["hosts"]:
        raise Fail(f"unknown host {host!r}; configured: {', '.join(sorted(cfg['hosts']))}")
    return host, cfg["hosts"][host]


def host_url(cfg, host):
    host, e = host_entry(cfg, host)
    return (e.get("localUrl") if host == cfg["self"] else None) or e["url"]


def token_file(host):
    return os.path.join(state_dir("tokens"), f"{host}.json")


def load_token(host):
    """The token record for host: {token, expiresAt, sessionId, source}."""
    try:
        with open(token_file(host)) as f:
            rec = json.load(f)
        rec["source"] = "fleet-t3"
        return rec
    except FileNotFoundError:
        pass
    # Pre-fleet-t3 hand-paired credential (~/.config/fleet-t3/<host>.mcp), read in place.
    legacy = os.path.expanduser(f"~/.config/fleet-t3/{host}.mcp")
    if os.path.exists(legacy):
        with open(legacy) as f:
            return {"token": f.read().strip(), "expiresAt": None, "sessionId": None, "source": "legacy"}
    return None


# ---------------------------------------------------------------- MCP client


class Remote:
    """One remote T3 server's MCP endpoint. A fresh MCP session per call keeps
    it stateless (a long wait on one thread never blocks another call)."""

    def __init__(self, cfg, host):
        self.host, _ = host_entry(cfg, host)
        self.base = host_url(cfg, self.host).rstrip("/")
        rec = load_token(self.host)
        if not rec:
            raise AuthFail(f"no token for {self.host}; run `fleet-t3 pair {self.host}`")
        self._token = rec["token"]

    def _post(self, body, session, timeout):
        h = {
            "Authorization": "Bearer " + self._token,
            "Content-Type": "application/json",
            "Accept": "application/json, text/event-stream",
        }
        if session:
            h["Mcp-Session-Id"] = session
        req = urllib.request.Request(self.base + "/mcp", data=json.dumps(body).encode(), headers=h, method="POST")
        try:
            with urllib.request.urlopen(req, timeout=timeout) as r:
                sid = r.headers.get("Mcp-Session-Id") or session
                raw = r.read().decode()
        except urllib.error.HTTPError as e:
            if e.code in (401, 403):
                raise AuthFail(f"{self.host} rejected the token (HTTP {e.code}); run `fleet-t3 pair {self.host}`")
            raise Fail(f"{self.host}: HTTP {e.code} {e.read()[:200].decode(errors='replace')}")
        except (urllib.error.URLError, OSError) as e:
            raise Unreachable(f"{self.host} unreachable ({getattr(e, 'reason', e)})")
        if not raw.strip():
            return sid, None
        if raw.lstrip().startswith("{"):
            return sid, json.loads(raw)
        msgs = [json.loads(l[5:]) for l in raw.splitlines() if l.startswith("data:") and l[5:].strip()]
        return sid, (msgs[-1] if msgs else None)

    def _session(self, fn, timeout):
        sid, _ = self._post(
            {
                "jsonrpc": "2.0",
                "id": 1,
                "method": "initialize",
                "params": {
                    "protocolVersion": "2025-06-18",
                    "capabilities": {},
                    "clientInfo": {"name": "fleet-t3", "version": VERSION},
                },
            },
            None,
            30,
        )
        self._post({"jsonrpc": "2.0", "method": "notifications/initialized"}, sid, 30)
        try:
            return fn(sid)
        finally:
            try:
                req = urllib.request.Request(
                    self.base + "/mcp",
                    headers={"Authorization": "Bearer " + self._token, "Mcp-Session-Id": sid or ""},
                    method="DELETE",
                )
                urllib.request.urlopen(req, timeout=5).close()
            except Exception:
                pass

    def tools(self):
        def go(sid):
            _, res = self._post({"jsonrpc": "2.0", "id": 2, "method": "tools/list"}, sid, 60)
            return res["result"]["tools"]

        return self._session(go, 60)

    def call(self, tool, args=None, timeout=120):
        """Call a remote tool; returns its decoded JSON (or text) result."""

        def go(sid):
            _, res = self._post(
                {"jsonrpc": "2.0", "id": 2, "method": "tools/call", "params": {"name": tool, "arguments": args or {}}},
                sid,
                timeout,
            )
            if res is None:
                raise Fail(f"{self.host}: empty response to {tool}")
            if "error" in res:
                raise Fail(f"{self.host} {tool}: {res['error'].get('message', res['error'])}")
            r = res.get("result", {})
            text = "\n".join(c.get("text", "") for c in r.get("content", []) if c.get("type") == "text")
            try:
                out = json.loads(text)
            except ValueError:
                out = text
            if r.get("isError") or (isinstance(out, dict) and str(out.get("_tag", "")).endswith("Failure")):
                msg = out.get("message", text) if isinstance(out, dict) else text
                raise Fail(f"{self.host} {tool}: {msg}")
            return out

        return self._session(go, timeout)


# ---------------------------------------------------------------- pairing


def run_t3(cfg, host, t3_args, input_bytes=None):
    """Run `t3 <args>` as the T3 owner on host (locally for this machine,
    else over SSH). Returns stdout bytes; stderr is passed through."""
    host, e = host_entry(cfg, host)
    path = '"$HOME/.local/bin:/opt/homebrew/bin:/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin:$PATH"'
    script = f"PATH={path}; exec t3 " + " ".join(shlex.quote(a) for a in t3_args)
    if host == cfg["self"]:
        argv = ["/bin/sh", "-c", script]
    else:
        ssh = e.get("ssh")
        if not ssh:
            raise Fail(f"{host} has no ssh target configured; use `fleet-t3 pair {host} --oauth`")
        argv = ["ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=10", ssh, "/bin/sh -c " + shlex.quote(script)]
    try:
        r = subprocess.run(argv, input=input_bytes, stdout=subprocess.PIPE, timeout=60)
    except subprocess.TimeoutExpired:
        raise Unreachable(f"{host}: `t3 {t3_args[0]}` timed out")
    if r.returncode != 0:
        if r.returncode == 255:
            raise Unreachable(f"{host}: ssh failed (offline or no access)")
        raise Fail(f"{host}: `t3 {' '.join(t3_args[:3])}` exited {r.returncode}")
    return r.stdout


def save_token(host, token, expires_at, session_id, method, label=None):
    write_private(
        token_file(host),
        json.dumps(
            {
                "token": token,
                "expiresAt": expires_at,
                "sessionId": session_id,
                "method": method,
                "label": label,
                "pairedAt": now().isoformat(),
            }
        ),
    )


def http_json(url, payload, form=False, timeout=20):
    data = urllib.parse.urlencode(payload).encode() if form else json.dumps(payload).encode()
    ctype = "application/x-www-form-urlencoded" if form else "application/json"
    req = urllib.request.Request(url, data=data, headers={"Content-Type": ctype, "Accept": "application/json"}, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return json.loads(r.read() or b"{}")
    except urllib.error.HTTPError as e:
        body = e.read()[:300].decode(errors="replace")
        raise Fail(f"{url.split('?')[0]}: HTTP {e.code} {body}")
    except (urllib.error.URLError, OSError) as e:
        raise Unreachable(f"{url.split('/oauth')[0]} unreachable ({getattr(e, 'reason', e)})")


def label_prefix(cfg, host):
    return f"fleet-t3 {cfg['self']}->{host}"


def pair_ssh(cfg, host):
    """Pair with host without a browser: mint a one-time pairing code on host
    over SSH (`t3 auth pairing create`), and use it to approve fleet-t3's own
    MCP OAuth request at full-access, the decision T3's consent page makes
    when you type a pairing code. T3 issues MCP client tokens for 30 days."""
    host, _ = host_entry(cfg, host)
    base = host_url(cfg, host).rstrip("/")
    label = f"{label_prefix(cfg, host)} {now().strftime('%Y%m%dT%H%M%SZ')}"
    redirect = "http://127.0.0.1:53682/callback"  # never contacted: the code comes back in the decision response
    client = http_json(
        base + "/oauth/mcp/register",
        {
            "client_name": label,
            "redirect_uris": [redirect],
            "token_endpoint_auth_method": "none",
            "grant_types": ["authorization_code"],
            "response_types": ["code"],
        },
    )
    args = ["auth", "pairing", "create", "--ttl", "5m", "--label", f"{label} approval", "--json"]
    for s in FULL_ACCESS_SCOPES:
        args += ["--scope", s]
    try:
        code = json.loads(run_t3(cfg, host, args))["credential"]
    except (ValueError, KeyError):
        raise Fail(f"{host}: unexpected `t3 auth pairing create` output")
    verifier = secrets.token_urlsafe(48)
    challenge = base64.urlsafe_b64encode(hashlib.sha256(verifier.encode()).digest()).rstrip(b"=").decode()
    state = secrets.token_urlsafe(12)
    authorization = {
        "response_type": "code",
        "client_id": client["client_id"],
        "redirect_uri": redirect,
        "code_challenge": challenge,
        "code_challenge_method": "S256",
        "state": state,
        "resource": base + "/mcp",
    }
    d = http_json(
        base + "/oauth/mcp/decision",
        {"authorization": authorization, "decision": {"_tag": "pairing-code", "access": "full-access", "code": code}},
    )
    q = urllib.parse.parse_qs(urllib.parse.urlparse(d.get("redirectTo", "")).query)
    if q.get("state", [""])[0] != state or "code" not in q:
        raise Fail(f"{host}: approval did not return a code ({q.get('error', ['?'])[0]})")
    tok = http_json(
        base + "/oauth/mcp/token",
        {
            "grant_type": "authorization_code",
            "code": q["code"][0],
            "redirect_uri": redirect,
            "client_id": client["client_id"],
            "code_verifier": verifier,
            "resource": base + "/mcp",
        },
        form=True,
    )
    exp = (now() + timedelta(seconds=int(tok["expires_in"]))).isoformat() if tok.get("expires_in") else None
    # Prove the new token before replacing the old one.
    probe = Remote.__new__(Remote)
    probe.host, probe.base, probe._token = host, base, tok["access_token"]
    probe.tools()
    save_token(host, tok["access_token"], exp, None, "ssh", label)
    return {"host": host, "expiresAt": exp, "scope": tok.get("scope"), "revokedPrevious": revoke_previous(cfg, host, label)}


def revoke_previous(cfg, host, keep_label):
    """Revoke this machine's earlier fleet-t3 sessions on host (by label prefix)."""
    try:
        sessions = json.loads(run_t3(cfg, host, ["auth", "session", "list", "--json"]))
    except (Fail, ValueError) as e:
        return f"not checked ({e})"
    if isinstance(sessions, dict):
        sessions = sessions.get("sessions", [])
    prefix = label_prefix(cfg, host)
    revoked = 0
    for s in sessions:
        lbl = (s.get("client") or {}).get("label") or ""
        if s.get("subject") == "mcp-client" and lbl.startswith(prefix) and lbl != keep_label:
            try:
                run_t3(cfg, host, ["auth", "session", "revoke", s["sessionId"]])
                revoked += 1
            except Fail:
                pass
    return revoked


def pair_oauth(cfg, host, redirect_base, port, timeout_s=1800):
    """Browser-consent pairing (OAuth 2.1 + PKCE, public client). The consent
    URL is printed; the redirect must reach 127.0.0.1:PORT on this machine
    (e.g. Tailscale Serve REDIRECT_BASE -> 127.0.0.1:PORT)."""
    host, _ = host_entry(cfg, host)
    base = host_url(cfg, host).rstrip("/")
    redirect = redirect_base.rstrip("/") + "/callback"

    def post(url, data, ctype):
        r = urllib.request.Request(url, data=data, headers={"Content-Type": ctype}, method="POST")
        with urllib.request.urlopen(r, timeout=20) as resp:
            return json.loads(resp.read())

    client = post(
        base + "/oauth/mcp/register",
        json.dumps(
            {
                "client_name": f"fleet-t3 ({cfg['self']})",
                "redirect_uris": [redirect],
                "token_endpoint_auth_method": "none",
                "grant_types": ["authorization_code"],
                "response_types": ["code"],
            }
        ).encode(),
        "application/json",
    )
    verifier = secrets.token_urlsafe(48)
    challenge = base64.urlsafe_b64encode(hashlib.sha256(verifier.encode()).digest()).rstrip(b"=").decode()
    state = secrets.token_urlsafe(12)
    url = (
        base
        + "/oauth/mcp/authorize?"
        + urllib.parse.urlencode(
            {
                "response_type": "code",
                "client_id": client["client_id"],
                "redirect_uri": redirect,
                "code_challenge": challenge,
                "code_challenge_method": "S256",
                "scope": " ".join(FULL_ACCESS_SCOPES),
                "state": state,
                "resource": base + "/mcp",
            }
        )
    )
    print(f"Open this URL and approve fleet-t3 on {host}:\n{url}", flush=True)
    got = {}

    class H(http.server.BaseHTTPRequestHandler):
        def do_GET(self):
            q = urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query)
            ok = q.get("state", [""])[0] == state and "code" in q
            if ok:
                got["code"] = q["code"][0]
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            self.wfile.write(b"Connected. You can close this tab." if ok else b"That link did not match; nothing was connected.")

        def log_message(self, *a):
            pass

    srv = http.server.HTTPServer(("127.0.0.1", port), H)
    srv.timeout = 30
    deadline = time.time() + timeout_s
    while "code" not in got and time.time() < deadline:
        srv.handle_request()
    if "code" not in got:
        raise Fail("no approval received")
    tok = post(
        base + "/oauth/mcp/token",
        urllib.parse.urlencode(
            {
                "grant_type": "authorization_code",
                "code": got["code"],
                "redirect_uri": redirect,
                "client_id": client["client_id"],
                "code_verifier": verifier,
                "resource": base + "/mcp",
            }
        ).encode(),
        "application/x-www-form-urlencoded",
    )
    exp = (now() + timedelta(seconds=int(tok["expires_in"]))).isoformat() if tok.get("expires_in") else None
    save_token(host, tok["access_token"], exp, None, "oauth")
    return {"host": host, "expiresAt": exp, "method": "oauth"}


def host_status(cfg, host, probe=False):
    rec = load_token(host)
    st = {"host": host, "url": host_url(cfg, host), "self": host == cfg["self"]}
    if not rec:
        st["token"] = "missing"
    else:
        st["token"] = rec["source"]
        exp = parse_ts(rec.get("expiresAt"))
        st["expiresAt"] = rec.get("expiresAt")
        if exp:
            left = exp - now()
            st["daysLeft"] = round(left.total_seconds() / 86400, 1)
            if left < timedelta(0):
                st["warning"] = "expired: run `fleet-t3 pair %s`" % host
            elif left < WARN_BEFORE:
                st["warning"] = "expires soon: run `fleet-t3 pair %s`" % host
    if probe and rec:
        try:
            Remote(cfg, host).tools()
            st["reachable"] = True
        except Fail as e:
            st["reachable"] = False
            st["error"] = str(e)
    return st


def renew(cfg, force=False):
    """Mint a fresh token for every host whose token is missing, legacy, or
    within RENEW_BEFORE of expiry. Unreachable hosts are skipped (retried on
    the next run)."""
    out = []
    for host in sorted(cfg["hosts"]):
        rec = load_token(host)
        exp = parse_ts(rec.get("expiresAt")) if rec else None
        due = force or not rec or rec["source"] != "fleet-t3" or (exp is not None and exp - now() < RENEW_BEFORE)
        if not due:
            out.append({"host": host, "action": "ok", "expiresAt": rec.get("expiresAt")})
            continue
        if host != cfg["self"] and not cfg["hosts"][host].get("ssh"):
            out.append({"host": host, "action": "skipped", "error": "no ssh target: re-pair with --oauth"})
            continue
        try:
            r = pair_ssh(cfg, host)
            out.append({"host": host, "action": "renewed", "expiresAt": r["expiresAt"]})
        except Fail as e:
            out.append({"host": host, "action": "skipped", "error": str(e)})
    return out


# ---------------------------------------------------------------- thread helpers


def thread_summary(remote, thread_id, chars=4000):
    """Status, title and the last assistant message of a thread."""
    head = remote.call("t3_thread_read", {"threadId": thread_id, "limit": 1, "maxCharsPerItem": 1})
    th = head["thread"]
    after = max(0, int(th.get("itemCount") or 0) - 12)
    tail = remote.call("t3_thread_read", {"threadId": thread_id, "afterPosition": after, "limit": 100, "maxCharsPerItem": 50000})
    msgs = [i for i in tail.get("items", []) if i.get("type") == "assistant_message"]
    last = (msgs[-1].get("text") or "") if msgs else ""
    return {
        "host": remote.host,
        "threadId": thread_id,
        "title": th.get("title"),
        "status": th.get("status"),
        "model": th.get("model"),
        "pendingRequestCount": th.get("pendingRequestCount", 0),
        "pullRequests": [p.get("url") for p in th.get("pullRequests") or [] if isinstance(p, dict)],
        "lastAssistantMessage": (("…" + last[-chars:]) if len(last) > chars else last),
    }


def wait_thread(remote, thread_id, timeout_s):
    """Block until the thread's run stops or timeout_s passes."""
    deadline = time.time() + timeout_s
    seen_active = False
    while True:
        left = deadline - time.time()
        if left <= 0:
            break
        chunk = min(WAIT_CHUNK_S, left)
        t0 = time.time()
        r = remote.call("t3_thread_wait", {"threadId": thread_id, "timeoutMs": int(chunk * 1000)}, timeout=chunk + 60)
        st = r.get("status") if isinstance(r, dict) else None
        if st in ACTIVE:
            seen_active = True
            if st == "waiting":
                break  # needs an answer: surface it now
        if not r.get("timedOut") and (st in TERMINAL or (st == "idle" and seen_active)):
            break
        if st == "idle" and not seen_active:
            # Launched moments ago and not started yet; give it a minute.
            if time.time() - (deadline - timeout_s) > 120:
                break
        if time.time() - t0 < 5:
            time.sleep(min(15, max(0, deadline - time.time())))
    s = thread_summary(remote, thread_id)
    s["stillRunning"] = s["status"] in ACTIVE and s["status"] != "waiting"
    if s["status"] == "waiting" or s["pendingRequestCount"]:
        s["needsInput"] = True
    return s


# ---------------------------------------------------------------- watches


def watch_path(wid):
    return os.path.join(state_dir("watches"), f"{wid}.json")


def load_watch(wid):
    with open(watch_path(wid)) as f:
        return json.load(f)


def save_watch(w):
    write_private(watch_path(w["id"]), json.dumps(w, indent=1))


def self_cmd():
    exe = os.environ.get("FLEET_T3_BIN") or shutil.which("fleet-t3")
    return [exe] if exe else [sys.executable, "-I", os.path.abspath(__file__)]


def start_watch(cfg, host, thread_id, notify_thread, notify_host=None, mode="auto", max_hours=24):
    host, _ = host_entry(cfg, host)
    notify_host, _ = host_entry(cfg, notify_host or cfg["self"])
    if not notify_thread:
        raise Fail("notifyThreadId is required: your own thread id (currentThreadId from the local t3_thread_list)")
    Remote(cfg, host)  # fail now on a missing token
    Remote(cfg, notify_host)
    short = "".join(c for c in thread_id.split(":")[-1] if c.isalnum())[:8]
    wid = f"{host}-{short}-{uuid.uuid4().hex[:6]}"
    w = {
        "id": wid,
        "host": host,
        "threadId": thread_id,
        "notifyHost": notify_host,
        "notifyThreadId": notify_thread,
        "mode": mode,
        "maxHours": max_hours,
        "startedAt": now().isoformat(),
        "state": "starting",
    }
    save_watch(w)
    argv = self_cmd() + ["_watcher", wid]
    log = os.path.join(state_dir("logs"), f"{wid}.log")
    sysrun = shutil.which("systemd-run") or ("/run/current-system/sw/bin/systemd-run" if os.path.exists("/run/current-system/sw/bin/systemd-run") else None)
    if sys.platform.startswith("linux") and sysrun:
        # A transient user unit of its own, so a restart of the T3 service (whose
        # cgroup the calling agent runs in) doesn't take the watcher with it.
        unit = f"fleet-t3-watch-{wid}"
        r = subprocess.run(
            [sysrun, "--user", "--quiet", "--collect", f"--unit={unit}", f"--property=StandardOutput=append:{log}", f"--property=StandardError=append:{log}",
                *[f"--setenv={k}={os.environ[k]}" for k in ("FLEET_T3_CONFIG", "XDG_STATE_HOME", "PATH") if os.environ.get(k)], *argv],
            capture_output=True,
            text=True,
        )
        if r.returncode != 0:
            raise Fail(f"systemd-run failed: {r.stderr.strip()[:300]}")
        w["unit"] = unit
    else:
        with open(log, "a") as lf:
            p = subprocess.Popen(argv, stdin=subprocess.DEVNULL, stdout=lf, stderr=lf, start_new_session=True)
        w["pid"] = p.pid
    w["state"] = "running"
    w["log"] = log
    save_watch(w)
    return w


def notify(cfg, w, kind, text):
    r = Remote(cfg, w["notifyHost"])
    last = None
    for attempt in range(6):
        try:
            return r.call(
                "t3_thread_send",
                {
                    "threadId": w["notifyThreadId"],
                    "message": text,
                    "mode": w.get("mode") or "auto",
                    "clientRequestId": f"fleet-t3-{w['id']}-{kind}",
                },
            )
        except Unreachable as e:
            last = e
            time.sleep(10 * (attempt + 1))
    raise last


def format_report(s, kind):
    head = {
        "done": f"[fleet-t3] {s['host']} thread \"{s['title']}\" stopped: {s['status']}.",
        "input": f"[fleet-t3] {s['host']} thread \"{s['title']}\" is waiting for input ({s['pendingRequestCount']} pending request(s)).",
    }[kind]
    lines = [head, f"host={s['host']} threadId={s['threadId']} model={s.get('model')}"]
    if s.get("pullRequests"):
        lines.append("PRs: " + ", ".join(s["pullRequests"]))
    if s.get("lastAssistantMessage"):
        lines += ["Last assistant message:", s["lastAssistantMessage"][-2500:]]
    lines.append(f"(Full thread: fleet-t3 thread_read host={s['host']} threadId={s['threadId']}.)")
    return "\n".join(lines)


def run_watcher(wid):
    cfg = load_config()
    w = load_watch(wid)
    w["pid"] = os.getpid()
    save_watch(w)
    deadline = time.time() + float(w.get("maxHours", 24)) * 3600
    fails = 0
    asked = False

    def finish(state, **extra):
        w.update(state=state, endedAt=now().isoformat(), **extra)
        save_watch(w)
        print(f"{now().isoformat()} {wid}: {state}", flush=True)

    while time.time() < deadline:
        try:
            remote = Remote(cfg, w["host"])
            s = wait_thread(remote, w["threadId"], min(MAX_WAIT_S, deadline - time.time()))
            fails = 0
        except AuthFail as e:
            notify_safe(cfg, w, "authfail", f"[fleet-t3] watch {wid} stopped: {e}")
            return finish("failed", error=str(e))
        except Fail as e:
            fails += 1
            print(f"{now().isoformat()} {wid}: {e} (attempt {fails})", flush=True)
            time.sleep(min(60 * fails, 600))
            continue
        if s.get("needsInput"):
            if not asked:
                notify_safe(cfg, w, "input", format_report(s, "input"))
                asked = True
            time.sleep(60)
            continue
        asked = False
        if not s["stillRunning"]:
            ok = notify_safe(cfg, w, "done", format_report(s, "done"))
            return finish("done" if ok else "notify-failed", result={k: s[k] for k in ("status", "title", "pullRequests")})
    notify_safe(cfg, w, "timeout", f"[fleet-t3] watch {wid} gave up after {w.get('maxHours')} h; {w['host']} thread {w['threadId']} is still running or unreachable.")
    finish("timeout")


def notify_safe(cfg, w, kind, text):
    try:
        notify(cfg, w, kind, text)
        return True
    except Fail as e:
        print(f"{now().isoformat()} {w['id']}: notify failed: {e}", flush=True)
        return False


def alive(w):
    if w.get("unit"):
        r = subprocess.run(["systemctl", "--user", "is-active", "--quiet", w["unit"]])
        return r.returncode == 0
    if w.get("pid"):
        try:
            os.kill(w["pid"], 0)
            return True
        except OSError:
            return False
    return False


def list_watches(include_done=False):
    out = []
    d = state_dir("watches")
    for name in sorted(os.listdir(d)):
        if not name.endswith(".json"):
            continue
        try:
            w = json.load(open(os.path.join(d, name)))
        except ValueError:
            continue
        if w.get("state") in ("running", "starting") and not alive(w):
            w["state"] = "dead"
        if include_done or w["state"] in ("running", "starting", "dead"):
            out.append({k: w.get(k) for k in ("id", "host", "threadId", "notifyHost", "notifyThreadId", "state", "startedAt", "endedAt", "result")})
    return out


def cancel_watch(wid):
    w = load_watch(wid)
    if w.get("unit"):
        subprocess.run(["systemctl", "--user", "stop", w["unit"]], capture_output=True)
    elif w.get("pid"):
        try:
            os.kill(w["pid"], signal.SIGTERM)
        except OSError:
            pass
    w.update(state="cancelled", endedAt=now().isoformat())
    save_watch(w)
    return {"id": wid, "state": "cancelled"}


# ---------------------------------------------------------------- tools

HOST = {"type": "string", "description": "Fleet host: a name from the `hosts` tool (e.g. airlock, voyager, thebattleship), or `self`."}
THREAD = {"type": "string", "description": "Thread id on that host."}


def obj(props, required, extra=False):
    return {"type": "object", "properties": props, "required": required, "additionalProperties": extra}


def t_hosts(cfg, a):
    return {"self": cfg["self"], "hosts": [host_status(cfg, h, probe=bool(a.get("probe"))) for h in sorted(cfg["hosts"])]}


def t_launch(cfg, a):
    a = dict(a)
    host = a.pop("host")
    use_default = a.pop("useProjectDefaultModel", False)
    r = Remote(cfg, host)
    if not a.get("modelSelection") and not use_default:
        hint = ""
        if a.get("projectId"):
            try:
                p = r.call("t3_project_read", {"projectId": a["projectId"]})
                p = p.get("project", p)
                hint = f" This project's default is {json.dumps(p.get('defaultModelSelection'))}."
            except Fail:
                pass
        raise Fail(
            "Pass modelSelection (e.g. {\"instanceId\":\"claudeAgent\",\"model\":\"claude-opus-5-5\"}; see `capabilities`), "
            "or useProjectDefaultModel=true. A remote launch otherwise falls back to the project's default model, "
            "which can be a small one." + hint
        )
    # An MCP client outside a T3 thread launches approval-required by default,
    # which stalls an unattended remote thread on its first tool call.
    a.setdefault("runtimeMode", "full-access")
    out = r.call("t3_thread_launch", a, timeout=180)
    if isinstance(out, dict):
        out["host"] = r.host
        tid = out.get("threadId") or (out.get("thread") or {}).get("threadId")
        if tid:
            out["next"] = f"thread_watch host={r.host} threadId={tid} notifyThreadId=<your currentThreadId>, or thread_wait"
    return out


def passthrough(tool, timeout=120):
    def f(cfg, a):
        a = dict(a)
        r = Remote(cfg, a.pop("host"))
        return r.call(tool, a, timeout=timeout)

    return f


def t_thread_list(cfg, a):
    a = dict(a)
    r = Remote(cfg, a.pop("host"))
    if a.get("projectId"):
        return r.call("t3_thread_list", a)
    limit = int(a.get("limit") or 20)
    threads = []
    for p in r.call("t3_project_list", {}).get("projects", []):
        q = dict(a, projectId=p["id"], limit=limit)
        for t in r.call("t3_thread_list", q).get("threads", []):
            t["projectTitle"] = p.get("title")
            threads.append(t)
    threads.sort(key=lambda t: t.get("updatedAt") or "", reverse=True)
    keep = ("threadId", "title", "status", "model", "projectId", "projectTitle", "updatedAt", "pendingRequestCount", "pullRequests")
    for t in threads:
        t["pullRequests"] = [p.get("url") for p in t.get("pullRequests") or [] if isinstance(p, dict)]
    return {"host": r.host, "threads": [{k: t.get(k) for k in keep if k in t} for t in threads[:limit]]}


def t_project_list(cfg, a):
    r = Remote(cfg, a["host"])
    ps = r.call("t3_project_list", {}).get("projects", [])
    return {
        "host": r.host,
        "projects": [{k: p.get(k) for k in ("id", "title", "workspaceRoot", "defaultModelSelection")} for p in ps],
    }


def t_wait(cfg, a):
    secs = min(float(a.get("timeoutSeconds") or 600), MAX_WAIT_S)
    return wait_thread(Remote(cfg, a["host"]), a["threadId"], secs)


def t_watch(cfg, a):
    w = start_watch(
        cfg,
        a["host"],
        a["threadId"],
        a.get("notifyThreadId"),
        a.get("notifyHost"),
        a.get("mode") or "auto",
        float(a.get("maxHours") or 24),
    )
    return {
        "watchId": w["id"],
        "state": w["state"],
        "note": f"You'll get a message in thread {w['notifyThreadId']} on {w['notifyHost']} when {w['host']} thread {w['threadId']} stops or needs input. End your turn; don't poll.",
    }


def t_call(cfg, a):
    r = Remote(cfg, a["host"])
    if not a.get("tool"):
        return sorted(t["name"] for t in r.tools())
    return r.call(a["tool"], a.get("arguments") or {}, timeout=float(a.get("timeoutSeconds") or 120))


TOOLS = [
    ("hosts", "List fleet hosts this machine can drive, with token status (and reachability with probe=true).", obj({"probe": {"type": "boolean"}}, []), t_hosts),
    (
        "thread_launch",
        "Start a new top-level T3 thread on a host. Pass projectId (see project_list) or scratch=true, a title, the task in `message`, "
        "and modelSelection {instanceId, model, options} (see capabilities) — required unless useProjectDefaultModel=true. "
        "runtimeMode defaults to full-access (unattended). workspaceStrategy/interactionMode pass through to the host's t3_thread_launch. Then thread_watch it.",
        obj(
            {
                "host": HOST,
                "projectId": {"type": "string"},
                "scratch": {"type": "boolean"},
                "title": {"type": "string"},
                "message": {"type": "string"},
                "modelSelection": {"type": "object"},
                "useProjectDefaultModel": {"type": "boolean"},
                "runtimeMode": {"type": "string", "enum": ["approval-required", "auto-accept-edits", "auto", "full-access"]},
                "interactionMode": {"type": "string", "enum": ["default", "plan"]},
                "workspaceStrategy": {"type": "object"},
            },
            ["host", "title", "message"],
            extra=True,
        ),
        t_launch,
    ),
    (
        "thread_read",
        "Read a thread on a host: state plus a timeline page (messages view by default; view=activity for tool activity). Page with afterPosition=nextPosition.",
        obj(
            {
                "host": HOST,
                "threadId": THREAD,
                "view": {"type": "string", "enum": ["messages", "activity"]},
                "afterPosition": {"type": "integer"},
                "limit": {"type": "integer"},
                "maxCharsPerItem": {"type": "integer"},
                "itemId": {"type": "string"},
                "textOffset": {"type": "integer"},
            },
            ["host", "threadId"],
        ),
        passthrough("t3_thread_read"),
    ),
    (
        "thread_send",
        "Send a message to a thread on a host. mode: auto (start idle / steer active / queue), queue, steer, restart. Use a stable clientRequestId for retries.",
        obj(
            {
                "host": HOST,
                "threadId": THREAD,
                "message": {"type": "string"},
                "mode": {"type": "string", "enum": ["auto", "queue", "steer", "restart"]},
                "clientRequestId": {"type": "string"},
            },
            ["host", "threadId", "message"],
        ),
        passthrough("t3_thread_send"),
    ),
    (
        "thread_wait",
        "Block until a thread on a host stops (or needs input), up to timeoutSeconds (default 600, max 2700). Returns status, title, PRs and the last assistant message; stillRunning=true means call again or use thread_watch.",
        obj({"host": HOST, "threadId": THREAD, "timeoutSeconds": {"type": "number"}}, ["host", "threadId"]),
        t_wait,
    ),
    (
        "thread_watch",
        "Watch a thread on a host in the background and message YOUR thread (notifyThreadId = currentThreadId from the local t3-code t3_thread_list) when it stops or needs input, then end your turn: the message wakes you. Survives your session; lasts up to maxHours (default 24).",
        obj(
            {
                "host": HOST,
                "threadId": THREAD,
                "notifyThreadId": {"type": "string", "description": "Your own T3 thread id."},
                "notifyHost": {"type": "string", "description": "Host of the thread to notify (default: this machine)."},
                "mode": {"type": "string", "enum": ["auto", "queue", "steer"]},
                "maxHours": {"type": "number"},
            },
            ["host", "threadId", "notifyThreadId"],
        ),
        t_watch,
    ),
    ("watch_list", "List background watches (running, and finished with all=true).", obj({"all": {"type": "boolean"}}, []), lambda cfg, a: list_watches(bool(a.get("all")))),
    ("watch_cancel", "Stop a background watch.", obj({"watchId": {"type": "string"}}, ["watchId"]), lambda cfg, a: cancel_watch(a["watchId"])),
    (
        "thread_list",
        "List threads on a host, newest first. Without projectId it lists across all projects. Filters: statuses, titleContains, settled, limit.",
        obj(
            {"host": HOST, "projectId": {"type": "string"}, "statuses": {"type": "array", "items": {"type": "string"}}, "titleContains": {"type": "string"}, "settled": {"type": "boolean"}, "limit": {"type": "integer"}},
            ["host"],
        ),
        t_thread_list,
    ),
    ("thread_interrupt", "Interrupt a thread's active run on a host.", obj({"host": HOST, "threadId": THREAD}, ["host", "threadId"], extra=True), passthrough("t3_thread_interrupt")),
    (
        "thread_configure",
        "Change a thread's model/modes on a host (passes through to t3_thread_configure; see its schema with call tool=… ).",
        obj({"host": HOST, "threadId": THREAD}, ["host", "threadId"], extra=True),
        passthrough("t3_thread_configure"),
    ),
    ("project_list", "List projects on a host with id, workspaceRoot and default model.", obj({"host": HOST}, ["host"]), t_project_list),
    ("project_create", "Create a project on a host (passes through to t3_project_create).", obj({"host": HOST}, ["host"], extra=True), passthrough("t3_project_create")),
    ("project_update", "Update a project on a host, e.g. its defaultModelSelection (passes through to t3_project_update).", obj({"host": HOST, "projectId": {"type": "string"}}, ["host", "projectId"], extra=True), passthrough("t3_project_update")),
    ("capabilities", "A host's providers and models (orchestrator_capabilities), for modelSelection. Pass search to find a model.", obj({"host": HOST, "search": {"type": "string"}}, ["host"], extra=True), passthrough("orchestrator_capabilities")),
    (
        "call",
        "Escape hatch: call any T3 MCP tool on a host by name with raw arguments. Omit tool to list the host's tool names.",
        obj({"host": HOST, "tool": {"type": "string"}, "arguments": {"type": "object"}, "timeoutSeconds": {"type": "number"}}, ["host"]),
        t_call,
    ),
]
TOOL_MAP = {t[0]: t for t in TOOLS}


# ---------------------------------------------------------------- MCP server (stdio)

INSTRUCTIONS = (
    "fleet-t3 drives T3 Code threads on other fleet machines (each machine's own T3 server). "
    "Launch with an explicit modelSelection, then thread_watch with notifyThreadId = your currentThreadId "
    "(from the local t3-code t3_thread_list) and end your turn; the result arrives as a message. "
    "Use thread_wait only when you can't be woken (no T3 thread). Load the fleet-t3 skill for the full workflow."
)


def serve():
    out_lock = threading.Lock()
    pool = ThreadPoolExecutor(max_workers=8)

    def send(msg):
        with out_lock:
            sys.stdout.write(json.dumps(msg) + "\n")
            sys.stdout.flush()

    def handle_call(mid, params):
        name = params.get("name")
        args = params.get("arguments") or {}
        t = TOOL_MAP.get(name)
        if not t:
            return send({"jsonrpc": "2.0", "id": mid, "error": {"code": -32602, "message": f"unknown tool {name}"}})
        try:
            cfg = load_config()
            res = t[3](cfg, args)
            text = res if isinstance(res, str) else json.dumps(res, indent=1)
            send({"jsonrpc": "2.0", "id": mid, "result": {"content": [{"type": "text", "text": text}]}})
        except Fail as e:
            send({"jsonrpc": "2.0", "id": mid, "result": {"content": [{"type": "text", "text": str(e)}], "isError": True}})
        except Exception as e:  # never kill the server on one bad call
            send({"jsonrpc": "2.0", "id": mid, "result": {"content": [{"type": "text", "text": f"fleet-t3 internal error: {type(e).__name__}: {e}"}], "isError": True}})

    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            msg = json.loads(line)
        except ValueError:
            send({"jsonrpc": "2.0", "id": None, "error": {"code": -32700, "message": "parse error"}})
            continue
        method, mid = msg.get("method"), msg.get("id")
        if method == "initialize":
            pv = (msg.get("params") or {}).get("protocolVersion") or "2025-06-18"
            send(
                {
                    "jsonrpc": "2.0",
                    "id": mid,
                    "result": {
                        "protocolVersion": pv,
                        "capabilities": {"tools": {}},
                        "serverInfo": {"name": "fleet-t3", "version": VERSION},
                        "instructions": INSTRUCTIONS,
                    },
                }
            )
        elif method == "tools/list":
            send({"jsonrpc": "2.0", "id": mid, "result": {"tools": [{"name": n, "description": d, "inputSchema": s} for n, d, s, _ in TOOLS]}})
        elif method == "tools/call":
            pool.submit(handle_call, mid, msg.get("params") or {})
        elif method == "ping":
            send({"jsonrpc": "2.0", "id": mid, "result": {}})
        elif mid is not None:
            send({"jsonrpc": "2.0", "id": mid, "error": {"code": -32601, "message": f"method not found: {method}"}})
    pool.shutdown(wait=False, cancel_futures=True)


# ---------------------------------------------------------------- CLI

USAGE = """fleet-t3 — drive T3 Code threads on other fleet machines

  fleet-t3 mcp                         stdio MCP server (registered with Claude Code)
  fleet-t3 hosts [--probe]             hosts and token status
  fleet-t3 pair HOST                   pair over SSH: a one-time `t3 auth pairing create` code approves
                                       fleet-t3 at full-access (30-day token; `renew` keeps it fresh)
  fleet-t3 pair HOST --oauth REDIRECT_BASE PORT
                                       browser-consent pairing (no SSH to HOST)
  fleet-t3 renew [--force]             renew tokens near expiry (timer runs this daily)
  fleet-t3 tool NAME '{json}'          run a fleet-t3 tool, e.g. tool thread_read '{"host":"airlock","threadId":"…"}'
  fleet-t3 call HOST TOOL ['{json}']   raw call of HOST's T3 MCP tool
  fleet-t3 tools HOST                  HOST's T3 MCP tool names
  fleet-t3 schema HOST TOOL            input schema of HOST's T3 MCP tool
  fleet-t3 wait HOST THREAD [SECONDS]  block until the thread stops
  fleet-t3 watch HOST THREAD NOTIFY_THREAD [--notify-host H]
  fleet-t3 watches [--all] | unwatch ID
"""


def pj(x):
    print(x if isinstance(x, str) else json.dumps(x, indent=1))


def main(argv):
    if not argv or argv[0] in ("-h", "--help", "help"):
        print(USAGE)
        return 0
    cmd, rest = argv[0], argv[1:]
    if cmd == "mcp":
        serve()
        return 0
    if cmd == "--version":
        print(VERSION)
        return 0
    try:
        if cmd == "_watcher":
            run_watcher(rest[0])
            return 0
        cfg = load_config()
        if cmd == "hosts":
            pj(t_hosts(cfg, {"probe": "--probe" in rest}))
        elif cmd == "pair":
            if "--oauth" in rest:
                i = rest.index("--oauth")
                pj(pair_oauth(cfg, rest[0], rest[i + 1], int(rest[i + 2])))
            else:
                pj(pair_ssh(cfg, rest[0]))
        elif cmd == "renew":
            res = renew(cfg, force="--force" in rest)
            pj(res)
        elif cmd == "tool":
            t = TOOL_MAP.get(rest[0])
            if not t:
                raise Fail(f"unknown tool {rest[0]}; tools: {', '.join(TOOL_MAP)}")
            pj(t[3](cfg, json.loads(rest[1]) if len(rest) > 1 else {}))
        elif cmd == "call":
            pj(Remote(cfg, rest[0]).call(rest[1], json.loads(rest[2]) if len(rest) > 2 else {}, timeout=900))
        elif cmd == "tools":
            pj("\n".join(t["name"] for t in Remote(cfg, rest[0]).tools()))
        elif cmd == "schema":
            for t in Remote(cfg, rest[0]).tools():
                if t["name"] == rest[1]:
                    pj(t.get("inputSchema"))
        elif cmd == "wait":
            pj(wait_thread(Remote(cfg, rest[0]), rest[1], float(rest[2]) if len(rest) > 2 else MAX_WAIT_S))
        elif cmd == "watch":
            nh = rest[rest.index("--notify-host") + 1] if "--notify-host" in rest else None
            pj(t_watch(cfg, {"host": rest[0], "threadId": rest[1], "notifyThreadId": rest[2], "notifyHost": nh}))
        elif cmd == "watches":
            pj(list_watches("--all" in rest))
        elif cmd == "unwatch":
            pj(cancel_watch(rest[0]))
        else:
            print(USAGE, file=sys.stderr)
            return 2
    except Fail as e:
        print(f"fleet-t3: {e}", file=sys.stderr)
        return 1
    except IndexError:
        print(USAGE, file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
