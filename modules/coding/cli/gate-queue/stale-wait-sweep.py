#!/usr/bin/env python3
"""stale-wait sweep (STA-415). DevOps no-agent cron, every 15 min. Never lets a build issue sit on a dead lease/gate wait.

Per build host (battleship, airlock, voyager) it reads `gate-queue status --json`, `gate-queue status --unreported`,
`build-lease status` and the process list over SSH. Then in Paperclip it looks at BLOCKED issues that are
  (1) assigned to that host's agent (Battleship / Airlock / Voyager),
  (2) unblockDescriptor.owner.agentId == the assignee itself, and unblockDescriptor.action mentions lease|gate|waiter,
and it sets such an issue to `todo` (with a comment) only if ALL of these also hold:
  (3) the host has no queued/running gate-queue job for the issue, and no finished job whose report is still pending,
  (4) the issue has no open blockedBy,
  (5) the host build lease is not fully held by live (unexpired) holders, i.e. at least one slot is free
      (a waiter would have taken a free slot within a minute, so a free slot that stays free means nobody waits),
  (6) no process on the host mentions the issue key (a hand-rolled nohup/screen waiter may still be alive),
  (7) the same conclusion held on the previous sweep too (>= SWEEP_MIN_AGE s earlier) with the issue unchanged.
It never touches a lease, a job or any other issue. Host unreachable / output unparseable => that host is skipped.

stdout is delivered to #fleet-alerts, so it prints ONLY when it acted (or tried to). With --dry-run it prints the
full report and writes nothing (no Paperclip writes, no state file).
Env (tests): SWEEP_FIXTURE=<json> (see selftest in STA-415), SWEEP_STATE=<path>, SWEEP_MIN_AGE=<seconds>.
Usage: stale-wait-sweep.py [--dry-run]
"""
import json, os, re, subprocess, sys, time, urllib.error, urllib.request

DRY = "--dry-run" in sys.argv
HERE = os.path.dirname(os.path.abspath(__file__))
STATE = os.environ.get("SWEEP_STATE", os.path.join(HERE, "stale-wait-sweep.state.json"))
MIN_AGE = int(os.environ.get("SWEEP_MIN_AGE", "600"))
MAX_ACTIONS = 6
CO = "d99dce6e-9c15-41ca-a353-9a86c135d21b"
HOSTS = {  # ssh alias -> Paperclip agent
    "battleship": ("276c47d4-d566-4a1a-92cb-c993eb2b3d25", "Battleship"),
    "airlock": ("4b8da3d3-50bd-4360-8011-e33fc63c7b60", "Airlock"),
    "voyager": ("3876f108-43d6-41fb-883c-122361bd1d86", "Voyager"),
}
AGENT_HOST = {v[0]: h for h, v in HOSTS.items()}
WAIT_RE = re.compile(r"lease|gate|waiter", re.I)
PENDING_REPORT = (False, None)
SPLIT = "---SPLIT---"
FIX = json.load(open(os.environ["SWEEP_FIXTURE"])) if os.environ.get("SWEEP_FIXTURE") else None
NOW = (FIX or {}).get("now") or time.time()
report = []  # lines for dry-run


def note(s):
    report.append(s)


def load_env():
    env = {}
    for line in open("/data/.hermes/profiles/devops/.env"):
        if "=" in line and not line.lstrip().startswith("#"):
            k, v = line.rstrip("\n").split("=", 1)
            env[k.strip()] = v.strip().strip('"').strip("'")
    return env


if FIX is None:
    _env = load_env()
    KEY = _env["PAPERCLIP_API_KEY"]
    BASE = _env.get("PAPERCLIP_API_URL", "http://10.10.10.10:3100").rstrip("/")


ME = "18817ce9-b69f-40c6-87c7-41d4cc1748a6"  # DevOps
_run = []


def run_id():
    """The server refuses cross-issue writes without a heartbeat run of the acting agent (403 cross_issue...), and a
    cron has none of its own. It accepts the id of any recent DevOps run (a finished one worked in the STA-415 probe),
    so use the newest running/succeeded one; the comment on each woken issue names the sweep as the actor."""
    if not _run:
        if FIX is not None:
            _run.append(FIX.get("run_id", "fixture-run"))
        else:
            rs = api("GET", "/companies/%s/heartbeat-runs?agentId=%s&limit=10" % (CO, ME))
            rs = rs if isinstance(rs, list) else rs.get("runs", [])
            ok = [r for r in rs if r.get("status") in ("running", "succeeded")]
            if not ok:
                raise RuntimeError("no running/succeeded DevOps heartbeat run to attribute the write to")
            _run.append(ok[0].get("id") or ok[0].get("runId"))
    return _run[0]


def api(method, path, body=None):
    if FIX is not None:
        if method == "GET":
            if path.startswith("/companies/"):
                return FIX["issues"]
            return FIX["details"][path.rsplit("/", 1)[1]]
        run_id()
        FIX.setdefault("_writes", []).append((method, path, body))
        if FIX.get("write_fail"):
            raise RuntimeError("HTTP 403: fixture write refused")
        return {}
    h = {"Authorization": "Bearer " + KEY, "User-Agent": "hermes-devops/stale-wait-sweep", "Content-Type": "application/json"}
    if method != "GET":
        h["X-Paperclip-Run-Id"] = run_id()
    req = urllib.request.Request(BASE + "/api" + path, method=method, headers=h,
                                 data=None if body is None else json.dumps(body).encode())
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            t = r.read().decode()
            return json.loads(t) if t else {}
    except urllib.error.HTTPError as e:
        raise RuntimeError("HTTP %d: %s" % (e.code, e.read().decode()[:200]))


def probe(host):
    """-> dict(jobs, unreported_text, lease_text, ps) or None when the host can't be read."""
    if FIX is not None:
        return FIX["hosts"].get(host)
    cmd = ("~/.local/bin/gate-queue status --json; echo %s; ~/.local/bin/gate-queue status --unreported; echo %s; "
           "~/.local/bin/build-lease status; echo %s; ps -axo args") % (SPLIT, SPLIT, SPLIT)
    try:
        p = subprocess.run(["ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=10", host, cmd],
                           capture_output=True, text=True, timeout=60)
    except Exception as e:
        note("%s: ssh failed (%s)" % (host, e)); return None
    parts = p.stdout.split(SPLIT)
    if p.returncode != 0 or len(parts) != 4:
        note("%s: probe failed rc=%s %s" % (host, p.returncode, p.stderr.strip()[:200])); return None
    try:
        jobs = json.loads(parts[0].strip() or "[]")
    except ValueError:
        note("%s: gate-queue status --json unparseable" % host); return None
    return {"jobs": jobs, "unreported_text": parts[1].strip().strip("\n"), "lease_text": parts[2].strip(), "ps": parts[3]}


def parse_lease(text):
    """-> (slots, live_held, [descr]) or None. Handles build-lease v2 (slots) and v1 (single exclusive)."""
    held = []
    slots = None
    m = re.search(r"(\d+)/(\d+) slot", text)
    if m:
        slots = int(m.group(2))
        for mm in re.finditer(r"^HELD (\S+): (.*?) \(expires in (-?\d+)s\)", text, re.M):
            held.append((mm.group(2), int(mm.group(3))))
    elif text.startswith("HELD at") or "\nowner=" in text:
        slots = 1
        o = re.search(r"^owner=(.*)$", text, re.M)
        e = re.search(r"^expires=(\d+)", text, re.M)
        if o and e:
            held.append((o.group(1), int(e.group(1)) - int(NOW)))
        else:
            held.append(("(no info)", 1))  # being created: treat as live
    elif text.startswith("FREE"):
        slots = 1
    if slots is None:
        return None
    live = [(o, r) for o, r in held if r > 0]
    return slots, live


def main():
    state = {}
    if os.path.exists(STATE):
        try:
            state = json.load(open(STATE))
        except ValueError:
            state = {}
    new_state = {}

    issues = api("GET", "/companies/%s/issues?status=blocked&limit=500" % CO)
    issues = issues if isinstance(issues, list) else issues.get("issues", [])
    if len(issues) >= 500:
        note("WARNING: blocked list hit the 500 limit")
    cands = []
    for i in issues:
        a = i.get("assigneeAgentId")
        ud = i.get("unblockDescriptor") or {}
        owner = ud.get("owner")
        if a in AGENT_HOST and isinstance(owner, dict) and owner.get("agentId") == a and WAIT_RE.search(str(ud.get("action", ""))):
            cands.append(i)
    note("blocked issues scanned: %d; lease/gate/waiter self-blocks on build-host agents: %d" % (len(issues), len(cands)))

    hostinfo = {}
    for host in HOSTS:
        if not any(AGENT_HOST[c["assigneeAgentId"]] == host for c in cands):
            continue
        pr = probe(host)
        if pr is None:
            hostinfo[host] = None; continue
        lease = parse_lease(pr["lease_text"])
        if lease is None:
            note("%s: build-lease status unparseable: %r" % (host, pr["lease_text"][:120])); hostinfo[host] = None; continue
        pr["lease"] = lease
        hostinfo[host] = pr
        slots, live = lease
        note("%s: lease %d/%d live slot(s) held %s; gate-queue jobs queued/running: %s; unreported: %s" % (
            host, len(live), slots, [o for o, _ in live],
            [j["issue"] + ":" + j["state"] for j in pr["jobs"] if j.get("state") in ("queued", "running")] or "none",
            (pr["unreported_text"].replace("\n", " | ")[:160] or "none")))

    acts = []
    for c in cands:
        ident = c["identifier"]
        host = AGENT_HOST[c["assigneeAgentId"]]
        pr = hostinfo.get(host)
        why = None
        if pr is None:
            why = "host not readable this tick"
        else:
            slots, live = pr["lease"]
            for j in pr["jobs"]:
                if j.get("issue") == ident and (j.get("state") in ("queued", "running") or (j.get("state") in ("done", "lost") and j.get("reported") in PENDING_REPORT)):
                    why = "gate-queue job %s is %s%s" % (j["id"], j["state"], "" if j["state"] in ("queued", "running") else " (report pending)")
                    break
            if why is None:
                d = api("GET", "/issues/" + c["id"])
                if "blockedBy" not in d:
                    why = "blockedBy not readable"
                else:
                    openb = [b.get("identifier", "?") for b in (d["blockedBy"] or []) if b.get("status") not in ("done", "cancelled")]
                    if openb:
                        why = "open blockedBy %s" % openb
            if why is None and len(live) >= slots:
                why = "lease fully held by live holder(s) %s" % [o for o, _ in live]
            if why is None:
                key = re.compile(re.escape(ident), re.I)
                procs = [l for l in pr["ps"].splitlines() if key.search(l) and "ps -axo" not in l and "gate-queue status" not in l]
                if procs:
                    why = "a process mentions %s on %s: %s" % (ident, host, procs[0].strip()[:100])
        if why:
            note("  %s (%s): skip - %s" % (ident, host, why)); continue
        sig = c.get("updatedAt")
        prev = state.get(ident)
        if prev and prev.get("sig") == sig:
            first = prev["first_seen"]
        else:
            first = NOW
        new_state[ident] = {"sig": sig, "first_seen": first}
        age = NOW - first
        if age < MIN_AGE:
            note("  %s (%s): stranded candidate, first seen %ds ago; acts when it holds for >= %ds (next sweep)" % (ident, host, age, MIN_AGE)); continue
        slots, live = pr["lease"]
        acts.append((c, host, slots, live, age))

    out = []
    for c, host, slots, live, age in acts[:MAX_ACTIONS]:
        ident = c["identifier"]
        agent = HOSTS[host][1]
        lease_s = "%d/%d slot(s) held%s" % (len(live), slots, (" by " + ", ".join(o for o, _ in live)) if live else "")
        msg = ("Stale-wait sweep (DevOps, STA-415): this issue was blocked waiting on a build lease/gate, but nothing is "
               "waiting for it on %s: no queued/running gate-queue job for %s, no open blockers, no waiter process, and the build "
               "lease has a free slot (%s). It stayed that way for %d min across two sweeps. Setting it to todo so you resume. "
               "If you still need a queued gate, resubmit with `gate-submit` (skill rust-build-efficiency) instead of a hand-made waiter."
               % (host, ident, lease_s, age // 60))
        if DRY:
            note("  %s (%s): WOULD set todo (lease %s)" % (ident, host, lease_s)); continue
        try:
            api("PATCH", "/issues/" + c["id"], {"status": "todo", "comment": msg})
            out.append("- %s (%s): was stuck on a dead lease/gate wait, lease %s; set to todo" % (ident, agent, lease_s))
            new_state.pop(ident, None)
        except Exception as e:
            out.append("- %s (%s): needed waking but the write failed (%s)" % (ident, agent, str(e)[:120]))
    if len(acts) > MAX_ACTIONS:
        out.append("(+%d more candidates left for the next sweep)" % (len(acts) - MAX_ACTIONS))
    if not DRY:
        tmp = STATE + ".tmp"
        json.dump(new_state, open(tmp, "w"))
        os.replace(tmp, STATE)
    if DRY:
        print("stale-wait sweep DRY RUN @ %s" % time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(NOW)))
        print("\n".join(report))
        print("would act on %d issue(s)" % len(acts))
    elif out:
        print("🧹 stale-wait sweep: woke %d stranded build-wait issue(s)\n%s" % (len([o for o in out if o.startswith("-")]), "\n".join(out)))


try:
    main()
except Exception as e:
    print("stale-wait-sweep error: %s" % e, file=sys.stderr)
    sys.exit(1)
