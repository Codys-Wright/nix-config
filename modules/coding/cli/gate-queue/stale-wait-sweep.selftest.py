#!/usr/bin/env python3
"""Offline selftest for stale-wait-sweep.py (STA-415): fixture issues/hosts, no network, no writes."""
import json, os, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
SWEEP = os.path.join(HERE, "stale-wait-sweep.py")
BATT, AIR, VOY, CMD = ("276c47d4-d566-4a1a-92cb-c993eb2b3d25", "4b8da3d3-50bd-4360-8011-e33fc63c7b60",
                       "3876f108-43d6-41fb-883c-122361bd1d86", "34417abc-6485-45f6-8890-a29135084ad5")


def iss(n, agent, action, owner=None, status="blocked", upd="u1"):
    return {"id": "id-%d" % n, "identifier": "STA-%d" % n, "assigneeAgentId": agent, "status": status, "updatedAt": upd,
            "unblockDescriptor": {"owner": {"agentId": owner or agent}, "action": action}}


issues = [
    iss(1, VOY, "Waiting on voyager's build lease; gate runs later"),          # STRANDED -> act
    iss(2, VOY, "Waiting for gate", owner=CMD),                               # owner is not the assignee
    iss(3, VOY, "Captain must approve the rebuild"),                          # no lease/gate/waiter word
    iss(4, BATT, "waiter ~/wt/x.sh waits for the lease"),                     # queued gate-queue job
    iss(5, BATT, "gate pending on lease"),                                    # open blockedBy
    iss(6, VOY, "lease wait, waiter in screen"),                              # process mentions it
    iss(7, AIR, "gate after lease"),                                          # lease fully held (v1 format)
    iss(8, BATT, "gate pending lease"),                                       # done job, report pending
    iss(9, CMD, "waiting on the lease"),                                      # not a build-host agent
    iss(10, BATT, "gate lease", owner=BATT),                                  # STRANDED -> act (2nd action)
    iss(11, BATT, "lease expired holder"),                                    # only expired holder -> act
]
details = {i["id"]: {"blockedBy": []} for i in issues}
details["id-5"] = {"blockedBy": [{"identifier": "STA-99", "status": "in_progress"}]}
details["id-4"] = {"blockedBy": [{"identifier": "STA-98", "status": "done"}]}
NOWT = 1_800_000_000
hosts = {
    "voyager": {"jobs": [], "unreported_text": "(no jobs)", "lease_text": "0/1 slot(s) held (/x/.build-lease)\nFREE (/x/.build-lease)",
                "ps": "/usr/bin/python3 gate-queue daemon\nSCREEN -dmS sta-6 bash\n"},
    "battleship": {"jobs": [{"id": "J4", "issue": "STA-4", "state": "queued", "reported": False},
                            {"id": "J8", "issue": "STA-8", "state": "done", "reported": False},
                            {"id": "J0", "issue": "STA-11", "state": "done", "reported": "status"}],
                   "unreported_text": "", "lease_text": "HELD /d/.build-lease: gate-STA-4-aa (expires in 100s)\nHELD /d/.build-lease.1: old (expires in -50s)\n2/2 slot(s) held (/d/.build-lease)",
                   "ps": "sh run.sh\n"},
    "airlock": {"jobs": [], "unreported_text": "", "lease_text": "HELD at /v/.build-lease\nowner=STA-93\nhost=airlock\nacquired=%d\nexpires=%d" % (NOWT - 10, NOWT + 3000),
                "ps": "SCREEN -dmS sta-6 bash\n"},
}
fx = tempfile.NamedTemporaryFile("w", suffix=".json", delete=False)
st = tempfile.mktemp(suffix=".state.json")
failures = []


def run(extra, now, minage):
    fixture = {"issues": issues, "details": details, "hosts": hosts, "now": now}
    json.dump(fixture, open(fx.name, "w"))
    env = dict(os.environ, SWEEP_FIXTURE=fx.name, SWEEP_STATE=st, SWEEP_MIN_AGE=str(minage))
    p = subprocess.run([sys.executable, SWEEP] + extra, env=env, capture_output=True, text=True)
    return p.returncode, p.stdout, p.stderr


def check(name, cond, detail=""):
    print(("PASS " if cond else "FAIL ") + name)
    if not cond:
        failures.append(name); print("   ", detail)


# battleship: the 2-slot lease is 1 live (gate-STA-4) + 1 expired => a free slot exists
rc, out, err = run(["--dry-run"], NOWT, 0)
check("dry-run rc 0", rc == 0, err)
check("dry-run prints a report and writes no state", "DRY RUN" in out and not os.path.exists(st), out)
check("dry-run lists STA-1, STA-10, STA-11 as would-act", all(("%s (" % k) in out and "WOULD set todo" in out for k in ("STA-1", "STA-10", "STA-11")), out)
for k, why in (("STA-4", "job"), ("STA-5", "open blockedBy"), ("STA-6", "process"), ("STA-7", "fully held"), ("STA-8", "report pending")):
    line = [l for l in out.splitlines() if l.strip().startswith(k + " ")]
    check("%s skipped (%s)" % (k, why), bool(line) and "skip" in line[0] and why in line[0], out)
for k in ("STA-2", "STA-3", "STA-9"):
    check("%s never considered" % k, not any(l.strip().startswith(k + " ") for l in out.splitlines()), out)

# tick 1 (live mode, MIN_AGE 600): record only, no output, no write
rc, out, err = run([], NOWT, 600)
check("tick1 silent", rc == 0 and out == "", out + err)
check("tick1 state has 3 candidates", sorted(json.load(open(st))) == ["STA-1", "STA-10", "STA-11"], open(st).read())
# tick 2 15 min later: acts. Writes can't be seen in-process (separate process), so use a write-fail fixture and a normal one.
rc, out, err = run([], NOWT + 900, 600)
check("tick2 posts summary for 3 issues", rc == 0 and "woke 3" in out and "STA-1 (Voyager)" in out and "STA-10 (Battleship)" in out, out + err)
check("tick2 state emptied after success", json.load(open(st)) == {}, open(st).read())
# issue changed between ticks => timer restarts
issues[0]["updatedAt"] = "u2"
run([], NOWT + 1800, 600)
issues[0]["updatedAt"] = "u3"
rc, out, err = run([], NOWT + 1800 + 900, 600)
check("changed issue restarts the clock", "STA-1 " not in out.replace("STA-10", "").replace("STA-11", ""), out)
# write failure is reported, not hidden
os.remove(st)
run([], NOWT, 0)
fixture = {"issues": issues, "details": details, "hosts": hosts, "now": NOWT + 900, "write_fail": True}
json.dump(fixture, open(fx.name, "w"))
env = dict(os.environ, SWEEP_FIXTURE=fx.name, SWEEP_STATE=st, SWEEP_MIN_AGE="0")
p = subprocess.run([sys.executable, SWEEP], env=env, capture_output=True, text=True)
check("write failure surfaces in the post", "write failed" in p.stdout, p.stdout + p.stderr)
# unreadable host => nothing acted for it
hosts["voyager"] = None
os.remove(st)
run([], NOWT, 0)
rc, out, err = run([], NOWT + 900, 0)
check("unreadable host => its issues untouched", "STA-1 (" not in out and "STA-10" in out, out)

print("\nALL PASS" if not failures else "\nFAILED: %s" % failures)
sys.exit(1 if failures else 0)
