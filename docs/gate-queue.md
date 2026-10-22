# gate-queue: durable, lease-aware build gates that wake their issue (STA-402)

Evidence and the failure analysis: Researcher STA-377 (`task-reports/research/gate-waiters.md`).
Eight queued gates finished and none woke its issue: the detached notifier had no run id (403), a green
gate only commented (an assignee's comment wakes nobody), `PATCH todo` 409s while a `blockedBy` is open, two
gates had no notifier, and gates detached HEAD in the shared canonical tree and clobbered each other.

## What it is

One Python (stdlib, 3.9+) program, `modules/coding/cli/gate-queue/gate-queue`, three faces:

| Command | Purpose |
|---|---|
| `gate-submit <ISSUE> <repo-tree> <script> [flags]` | enqueue and return at once (same program, dispatches on argv[0]) |
| `gate-queue daemon` | the per-host daemon (systemd user unit / LaunchAgent) |
| `gate-queue status [--unreported] [--json] [JOB\|ISSUE]`, `cancel <JOB>`, `retry-report <JOB>` | operate |

`gate-submit` flags: `--sha SHA` (detach the tree there for the run, restore afterwards), `--timeout S`
(default 7200), `--exclusive` (all lease slots), `--no-lease` (canaries only), `--profile P` (Paperclip
profile, inferred when `~/.hermes/profiles/` has exactly one), `--run-id ID` (default `$PAPERCLIP_RUN_ID`;
required, `--no-run-id` only for a gate you collect by hand), `--on-done todo|in_review`.

## Behaviour

- **FIFO per repo tree** (realpath). Different trees run side by side, each under its own build-lease slot
  (`gate-<ISSUE>-<4 hex>`), renewed every 60 s (ttl 30 min), released in all outcomes.
- **HEAD swap** (`--sha`): refuses a tree with uncommitted tracked changes, takes a flock on `<gitdir>/gate.lock`,
  `git checkout --detach <sha>`, and afterwards restores the previous branch or sha. It never resets or forces;
  if the restore fails the report says so.
- **Isolation**: the script runs outside the daemon (Linux: `systemd-run --user --collect` unit
  `gate-<job>.service`; macOS: new session). Stopping or restarting the daemon, the Hermes gateway or an
  agent run never touches it. On start the daemon re-adopts running jobs; a job whose process vanished is
  `lost` and reported as such.
- **Run env**: `GATE_ISSUE GATE_JOB GATE_TREE GATE_SHA GATE_LOG_DIR PAPERCLIP_RUN_ID HERMES_PROFILE`;
  cwd = tree; output in `<root>/logs/<job>/gate.log`. A `summary.md` written to `$GATE_LOG_DIR` becomes the
  report body, otherwise the tail of `gate.log`.
- **Report** (green or red or lost): `pc -p <profile> status <ISSUE> todo "<summary + log path>"` with the
  *submitting* run's `PAPERCLIP_RUN_ID` (the server accepts a write with the id of any run of the same agent
  whose context had that issue, also after the run ended; it targets the run's own source issue, so the
  cross-issue cap does not apply). On `409`/`422` (open `blockedBy`, run-ownership conflict) it posts a comment
  instead, leaves the issue as is and logs `NOT WOKEN` in `events.log`, state `reported=comment-only`. On 403,
  5xx or network errors it retries with backoff for 24 h (`reported=false`, listed by
  `gate-queue status --unreported`).
- State: `~/gate-queue/{jobs,logs,heartbeat,daemon.lock}` (override `GATE_QUEUE_DIR`).

## Install

### THEBATTLESHIP (NixOS, user `agent`)

Nix (this PR, additive): `fleet.coding.cli/gate-queue` adds `gate-queue`/`gate-submit` to the system path and
the user unit `gate-queue.service` (`ConditionUser=agent`, `KillMode=process`, `Restart=always`). Linger is on,
so it starts with the user manager. **Taking effect needs a host rebuild and switch: Captain's yes/no.**

Hand-installed copy (live since STA-402, no rebuild):

```sh
scp modules/coding/cli/gate-queue/gate-queue battleship:.local/bin/gate-queue
ssh battleship 'ln -sf gate-queue ~/.local/bin/gate-submit; chmod +x ~/.local/bin/gate-queue; mkdir -p ~/.config/systemd/user ~/gate-queue'
# ~/.config/systemd/user/gate-queue.service: same ExecStart/KillMode/Restart as the Nix unit, ExecStart=%h/.local/bin/gate-queue daemon
ssh battleship 'systemctl --user daemon-reload && systemctl --user enable --now gate-queue'
```

At switch time remove the hand copy so the Nix one takes over (a unit in `~/.config/systemd/user` shadows
`/etc/systemd/user`): `systemctl --user disable --now gate-queue; rm ~/.config/systemd/user/gate-queue.service
~/.local/bin/gate-queue ~/.local/bin/gate-submit; systemctl --user daemon-reload; systemctl --user start gate-queue`.
Running gates are transient units and are re-adopted.

### airlock (macOS, user `rat`; no nix-darwin yet, manual placement)

```sh
scp modules/coding/cli/gate-queue/gate-queue airlock:.local/bin/gate-queue
ssh airlock 'ln -sf gate-queue ~/.local/bin/gate-submit; chmod +x ~/.local/bin/gate-queue; mkdir -p ~/gate-queue'
scp modules/coding/cli/gate-queue/ai.fts.gate-queue.plist airlock:Library/LaunchAgents/
ssh airlock 'launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/ai.fts.gate-queue.plist'
```

Two airlock specifics:

1. **TCC.** A plain LaunchAgent running `/usr/bin/python3` gets `Operation not permitted` reading inside
   `/Volumes/build-disk` (removable-volume TCC; only sshd-keygen-wrapper and the user-DB grant behind
   `/usr/bin/osascript` have it). The plist therefore starts the daemon the same way `ai.hermes.gateway` does,
   through `osascript -l JavaScript` + `$.system("exec python3 ...")`. Do not simplify it to a bare python
   `ProgramArguments` or the lease and every build-disk gate fail silently.
2. **AbandonProcessGroup** is set so launchd never signals a running gate's group. launchd then only
   signals osascript, so the daemon (`GATE_QUEUE_EXIT_WITH_PARENT=1`) stops itself when its parent goes away
   and launchd starts a fresh pair; running gates are re-adopted.

### voyager (macOS, user `CodyWright`, home `/Users/codywright`; manual placement) (STA-415)

voyager is the Captain's own login and its nix-darwin config is parked on STA-240, so like airlock this is a
hand placement (user-level LaunchAgent only; no rebuild, nothing system-wide). Same program, same
osascript start (TCC grants live on `/usr/bin/osascript`; reads of `/Volumes/dev-drive`
from a daemon-run gate were verified).

```sh
ssh voyager 'cp -p ~/.local/bin/pc ~/.local/bin/pc.pre-sta415.bak'          # the old pc lacks needs-captain/reclaim
scp modules/coding/cli/gate-queue/gate-queue voyager:.local/bin/gate-queue
ssh voyager 'ln -sf gate-queue ~/.local/bin/gate-submit; chmod +x ~/.local/bin/gate-queue; mkdir -p ~/gate-queue/{jobs,logs}'
scp modules/coding/cli/gate-queue/ai.fts.gate-queue.voyager.plist voyager:Library/LaunchAgents/ai.fts.gate-queue.plist
ssh voyager 'launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/ai.fts.gate-queue.plist'
```

The voyager plist is the airlock one with `/Users/codywright` paths and `~/.cargo/bin` on PATH. Invoke the tools by
absolute path in non-interactive ssh (`~/.local/bin/gate-queue ...`): voyager's zsh does not put `~/.local/bin` on PATH there
(Hermes' own shell does).

## Stale-wait sweep (STA-415)

`modules/coding/cli/gate-queue/stale-wait-sweep.py` (+ `stale-wait-sweep.selftest.py`, offline fixtures, no network) is a
no-agent Hermes cron in the DevOps profile (`every 15m`, delivery `#fleet-alerts`). It exists because a gate waiter that
dies leaves its issue `blocked` on a lease that is already free. On battleship, airlock and voyager it reads
`gate-queue status --json|--unreported`, `build-lease status` and the process list, and in Paperclip it considers only
BLOCKED issues assigned to that host's agent whose `unblockDescriptor.owner` is that same agent and whose `action`
mentions lease|gate|waiter. It sets such an issue to `todo` with a comment only if ALL hold: no queued/running (or
report-pending) gate-queue job for it, no open `blockedBy`, at least one live lease slot is free, no process on the host
mentions the issue key (hand-made nohup/screen waiter), and the same was true on the previous sweep (>= 10 min earlier,
issue unchanged). It never touches a lease, a job or any other issue, posts to #fleet-alerts only when it acts, and
`--dry-run` prints the full decision report without writing.

```sh
cp modules/coding/cli/gate-queue/stale-wait-sweep.py /data/.hermes/profiles/devops/scripts/
HERMES_HOME=/data/.hermes/profiles/devops hermes cron create --name stale-wait-sweep --no-agent \
  --script stale-wait-sweep.py --deliver discord:1562163078555111485 'every 15m' </dev/null
```

## Validation (STA-402)

Run on the container (macOS code path, stubbed `pc`), on THEBATTLESHIP and airlock (real), details in the PR.

## Rollback

- Hand installs: `systemctl --user disable --now gate-queue; rm ~/.config/systemd/user/gate-queue.service
  ~/.local/bin/gate-{queue,submit}` / `launchctl bootout gui/$(id -u)/ai.fts.gate-queue; rm
  ~/Library/LaunchAgents/ai.fts.gate-queue.plist ~/.local/bin/gate-{queue,submit}`. `~/gate-queue` is state and
  logs only; queued-but-unrun jobs are dropped, running scripts keep running. voyager additionally:
  `mv ~/.local/bin/pc.pre-sta415.bak ~/.local/bin/pc` restores the old pc.
- Sweep: `hermes -p devops cron remove stale-wait-sweep` (it holds no state outside `stale-wait-sweep.state.json`).
- Nix: revert this PR; the next switch removes the package and the unit (or `nixos-rebuild switch --rollback`).
