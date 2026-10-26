#!/usr/bin/env bash
# Point packages/task-desktop at a Task release: rewrite source.json from the
# release's latest-linux.json, which carries the AppImage's sha256, so
# nothing is downloaded but that small manifest.
#
#   packages/task-desktop/update.sh            the newest release
#   packages/task-desktop/update.sh v26.10.6   a given tag
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
repo="FastTrackStudios/task"

if [ "$#" -gt 0 ]; then
    url="https://github.com/$repo/releases/download/$1/latest-linux.json"
else
    url="https://github.com/$repo/releases/latest/download/latest-linux.json"
fi

manifest="$(curl -fsSL "$url")"
version="$(jq -r .version <<<"$manifest")"
hex="$(jq -r .sha256 <<<"$manifest")"
[ -n "$version" ] && [ "$version" != null ] || { echo "no version in $url" >&2; exit 1; }
[ "${#hex}" -eq 64 ] || { echo "no sha256 in $url" >&2; exit 1; }
hash="$(nix hash convert --hash-algo sha256 --to sri "$hex")"

jq -n --arg version "$version" --arg hash "$hash" '{version: $version, hash: $hash}' \
    >"$here/source.json"
echo "task-desktop: $version ($hash)"
