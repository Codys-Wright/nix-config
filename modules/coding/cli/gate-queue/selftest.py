#!/usr/bin/env python3
"""Self-test for gate-queue with a stubbed `pc` and a temp HOME (no network, no real lease).

    python3 selftest.py            # ~90 s

Covers: FIFO + HEAD swap/restore, green/red reporting with the submitting run id, 409 -> comment-only,
403 -> retry (reported stays false), daemon kill -9 mid-job -> re-adoption, vanished process -> lost,
timeout, cancel, dirty tree refusal, lease taken/released.
"""
import json, os, shutil, signal, subprocess, sys, tempfile, time

HERE = os.path.dirname(os.path.abspath(__file__))
GQ = os.path.join(HERE, "gate-queue")
T = tempfile.mkdtemp(prefix="gq-selftest-")
HOME = os.path.join(T, "home")
BIN = os.path.join(HOME, ".local", "bin")
os.makedirs(BIN)
ENV = dict(os.environ, HOME=HOME, GATE_QUEUE_DIR=os.path.join(HOME, "gate-queue"),
           BUILD_LEASE_DIR=os.path.join(T, "lease"), HERMES_PROFILE="selftest",
           PCLOG=os.path.join(T, "pc.log"), PCFAIL=os.path.join(T, "pc.fail"))
ENV.pop("PAPERCLIP_RUN_ID", None)

with open(os.path.join(BIN, "pc"), "w") as f:
    f.write('''#!/bin/sh
echo "$3 $4 run=$PAPERCLIP_RUN_ID" >> "$PCLOG"
if [ "$4" = STA-409 ] && [ "$3" = status ]; then echo 'pc: PATCH -> HTTP 409: unresolved blockers' >&2; exit 1; fi
if [ -f "$PCFAIL" ]; then echo 'pc: PATCH -> HTTP 403: cross_issue_influence_run_context_required' >&2; exit 1; fi
exit 0
''')
with open(os.path.join(BIN, "build-lease"), "w") as f:  # minimal mkdir lease, same CLI
    f.write('''#!/bin/sh
L="$BUILD_LEASE_DIR"; c=$1; o=$2
case $c in
 acquire) if mkdir "$L" 2>/dev/null; then echo "$o" > "$L/owner"; echo ACQUIRED; else echo "BUSY - lease held:"; echo "owner=$(cat $L/owner)"; exit 1; fi;;
 renew) exit 0;;
 release) [ "$(cat $L/owner 2>/dev/null)" = "$o" ] && rm -rf "$L"; exit 0;;
 slots) echo "slots=1";;
 status) ls "$L" >/dev/null 2>&1 && echo "HELD $L: $(cat $L/owner)" || echo FREE;;
esac
''')
for n in ("pc", "build-lease"):
    os.chmod(os.path.join(BIN, n), 0o755)

REPO = os.path.join(T, "repo")
def sh(*a, **k):
    return subprocess.run(list(a), env=ENV, capture_output=True, text=True, **k)
def git(*a):
    return subprocess.run(["git", "-C", REPO, "-c", "user.email=t@t", "-c", "user.name=t"] + list(a), capture_output=True, text=True).stdout.strip()
os.makedirs(REPO)
git("init", "-q")
git("commit", "-q", "--allow-empty", "-m", "one")
git("checkout", "-q", "-b", "main")
open(os.path.join(REPO, "f"), "w").write("a\n"); git("add", "f"); git("commit", "-q", "-m", "two")
git("checkout", "-q", "-b", "feat"); open(os.path.join(REPO, "f"), "w").write("b\n"); git("commit", "-q", "-am", "three")
git("checkout", "-q", "main")
FEAT = git("rev-parse", "feat")

def script(name, body):
    p = os.path.join(T, name)
    open(p, "w").write("#!/bin/sh\n" + body)
    os.chmod(p, 0o755)
    return p
green = script("green.sh", 'echo "at $(git rev-parse HEAD)" > "$GATE_LOG_DIR/where"; sleep 3; echo "# custom" > "$GATE_LOG_DIR/summary.md"\n')
red = script("red.sh", "sleep 1; echo oops; exit 3\n")
long_ = script("long.sh", "sleep 611\n")

def submit(issue, scr, *extra, run="run-" ):
    r = sh(sys.executable, GQ, "submit", issue, REPO, scr, "--run-id", run + issue, *extra)
    assert r.returncode == 0, r.stderr
    return r.stdout.split()[1]

def job(jid):
    return json.load(open(os.path.join(ENV["GATE_QUEUE_DIR"], "jobs", jid + ".json")))

def wait(jid, cond, secs=60):
    t = time.time()
    while time.time() - t < secs:
        j = job(jid)
        if cond(j):
            return j
        time.sleep(0.5)
    raise AssertionError("timeout waiting for %s: %s" % (jid, json.dumps(job(jid))[:400]))

def start_daemon():
    return subprocess.Popen([sys.executable, GQ, "daemon"], env=ENV, stdout=open(os.path.join(T, "daemon.log"), "a"), stderr=subprocess.STDOUT)

ok = []
def check(name, cond):
    print(("PASS " if cond else "FAIL ") + name)
    ok.append(bool(cond))

d = start_daemon()
time.sleep(1)
try:
    a = submit("STA-901", green, "--sha", FEAT)
    b = submit("STA-902", "true")
    c = submit("STA-903", red)
    e = submit("STA-409", "true")
    ja = wait(a, lambda j: j["reported"])
    jb = wait(b, lambda j: j["reported"]); jc = wait(c, lambda j: j["reported"]); je = wait(e, lambda j: j["reported"])
    check("FIFO: a finished before b started", ja["finished_at"] <= job(b)["started_at"] + 0.01)
    check("sha swap: script saw the feature sha", open(os.path.join(ENV["GATE_QUEUE_DIR"], "logs", a, "where")).read().strip() == "at " + FEAT)
    check("HEAD restored to branch main", git("symbolic-ref", "--short", "HEAD") == "main")
    check("green reported via status with the submitting run id", ja["reported"] == "status" and "status STA-901 run=run-STA-901" in open(ENV["PCLOG"]).read())
    check("summary.md used as body", "# custom" in ja["summary"])
    check("red reported (rc 3)", jc["rc"] == 3 and jc["reported"] == "status" and "Gate RED" in jc["summary"])
    check("409 -> comment-only, logged", je["reported"] == "comment-only" and "NOT WOKEN" in open(os.path.join(ENV["GATE_QUEUE_DIR"], "logs", e, "events.log")).read())
    check("lease released", not os.path.exists(ENV["BUILD_LEASE_DIR"]))

    open(ENV["PCFAIL"], "w").close()
    f = submit("STA-904", "true")
    jf = wait(f, lambda j: j.get("report_attempts", 0) >= 1)
    check("403 -> retry scheduled, reported stays false", jf["reported"] is False and "403" in jf["report_error"])
    os.unlink(ENV["PCFAIL"])
    sh(sys.executable, GQ, "retry-report", f)
    wait(f, lambda j: j["reported"] == "status", 30)
    check("retry-report delivers once pc recovers", True)

    g = submit("STA-910", long_)
    wait(g, lambda j: j["state"] == "running")
    d.send_signal(signal.SIGKILL); d.wait(); time.sleep(1)
    check("job survives daemon kill -9", job(g)["state"] == "running")
    d = start_daemon(); time.sleep(4)
    sh(sys.executable, GQ, "cancel", g)
    jg = wait(g, lambda j: j["state"] == "cancelled", 30)
    check("re-adopted after restart, then cancel stops it", jg["state"] == "cancelled")

    h = submit("STA-920", long_, "--timeout", "5")
    jh = wait(h, lambda j: j["reported"], 40)
    check("timeout -> rc 124 and reported", jh["rc"] == 124)

    i = submit("STA-921", long_)
    wait(i, lambda j: j["state"] == "running")
    pid = int(open(os.path.join(ENV["GATE_QUEUE_DIR"], "logs", i, "pid")).read())
    os.kill(pid, signal.SIGKILL)
    ji = wait(i, lambda j: j["reported"], 40)
    check("vanished process -> lost, reported", ji["state"] == "lost")

    m = sh(sys.executable, GQ, "submit", "STA-930", "true", REPO, "--no-run-id").returncode  # args misordered on purpose: must be rejected
    check("bad argument order rejected", m != 0)
    r = sh(sys.executable, GQ, "submit", "STA-931", REPO, "true", "--no-run-id")
    n = r.stdout.split()[1]
    jn = wait(n, lambda j: j["state"] == "done", 30); time.sleep(6)
    check("--no-run-id job is never reported (n/a, no pc call)", job(n)["reported"] == "n/a" and "STA-931" not in open(ENV["PCLOG"]).read())

    open(os.path.join(REPO, "f"), "a").write("dirty\n")
    k = submit("STA-923", "true", "--sha", FEAT)
    jk = wait(k, lambda j: j["reported"], 30)
    check("dirty tree refused (rc 98), nothing moved", jk["rc"] == 98 and git("symbolic-ref", "--short", "HEAD") == "main")
finally:
    try:
        d.terminate(); d.wait(timeout=10)
    except Exception:
        pass
    subprocess.run(["pkill", "-9", "-f", "^sleep 611$"])
    shutil.rmtree(T, ignore_errors=True)
print("%d/%d passed" % (sum(ok), len(ok)))
sys.exit(0 if all(ok) else 1)
