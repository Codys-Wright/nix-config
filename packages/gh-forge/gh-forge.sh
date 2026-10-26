#!/bin/sh
# gh-forge: the real gh, authenticated as the FTS - Forge GitHub App
# (fts-forge[bot]). Installed as `gh` for agents, so `gh pr create` etc. act
# as the bot with a short-lived installation token minted per invocation.
#
# The installation (owner) is picked from, in order: $GH_FORGE_OWNER,
# -R/--repo OWNER/REPO, a github.com URL argument, an `api repos/OWNER/...`
# path, $GH_REPO, the current repo's github.com remote (origin, else the
# first). An owner the app isn't installed on falls back to its default
# installation (FastTrackStudios).
#
#   GH_FORGE=0 gh ...   run plain gh with your own login (no bot token)
#   GH_FORGE=1 gh ...   act as the bot (the default on an agent account; a
#                       human account's build defaults to 0)
#
# If no App key is readable here, it warns once and runs plain gh.
# @GH@ / @TOKEN@ / @DEFAULT@ are substituted with store paths at build time.
GH=@GH@
TOKEN=@TOKEN@
APP=${GH_FORGE_APP:-fts-forge}

[ "${GH_FORGE:-@DEFAULT@}" = 0 ] && exec "$GH" "$@"

owner_of() { # owner from OWNER/REPO, a github URL, or nothing
  r=$1
  case $r in
  https://github.com/*) r=${r#https://github.com/} ;;
  http://github.com/*) r=${r#http://github.com/} ;;
  git@github.com:*) r=${r#git@github.com:} ;;
  ssh://git@github.com/*) r=${r#ssh://git@github.com/} ;;
  github.com/*) r=${r#github.com/} ;;
  *://* | *@*:*) return ;;
  esac
  case $r in
  */*) printf '%s\n' "${r%%/*}" ;;
  esac
}

owner=${GH_FORGE_OWNER:-}
if [ -z "$owner" ]; then
  prev=
  for a in "$@"; do
    case $prev in -R | --repo) owner=$(owner_of "$a") ;; esac
    case $a in
    --repo=*) owner=$(owner_of "${a#--repo=}") ;;
    -R?*) owner=$(owner_of "${a#-R}") ;;
    repos/*/* | /repos/*/*) [ -z "$owner" ] && { a=${a#/}; a=${a#repos/}; owner=${a%%/*}; } ;;
    https://github.com/*/* | http://github.com/*/*) owner=$(owner_of "$a") ;;
    esac
    [ -n "$owner" ] && break
    prev=$a
  done
fi
if [ -z "$owner" ] && [ -n "${GH_REPO:-}" ]; then owner=$(owner_of "$GH_REPO"); fi
if [ -z "$owner" ] && command -v git >/dev/null 2>&1; then
  url=$(git remote get-url origin 2>/dev/null) || {
    first=$(git remote 2>/dev/null | head -n1)
    url=
    [ -n "$first" ] && url=$(git remote get-url "$first" 2>/dev/null)
  }
  [ -n "$url" ] && owner=$(owner_of "$url")
fi

if tok=$("$TOKEN" "$APP" ${owner:+--owner "$owner"} --fallback 2>/dev/null) && [ -n "$tok" ]; then
  GH_TOKEN=$tok
  export GH_TOKEN
  unset GITHUB_TOKEN GH_ENTERPRISE_TOKEN
  exec "$GH" "$@"
fi
echo "gh-forge: could not mint an $APP token (no readable App key here?); running plain gh" >&2
exec "$GH" "$@"
