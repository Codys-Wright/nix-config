#!/usr/bin/env bash
# Point packages/drive-release (and drive-app-release, Drive.app) at a Drive
# release: rewrite source.json from the release's SHA256SUMS, so nothing is
# downloaded but that small file.
#
#   packages/drive-release/update.sh            the newest release
#   packages/drive-release/update.sh v26.11.2   a given tag
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
repo="FastTrackStudios/drive"

if [ "$#" -gt 0 ]; then
    base="https://github.com/$repo/releases/download/$1"
else
    base="https://github.com/$repo/releases/latest/download"
fi

sums="$(curl -fsSL "$base/SHA256SUMS")"
version="$(grep -oE 'drive-[0-9]+\.[0-9]+\.[0-9]+-aarch64-apple-darwin' <<<"$sums" | head -1 | sed -E 's/^drive-([0-9.]+)-.*/\1/')"
[ -n "$version" ] || { echo "no macOS tarball in $base/SHA256SUMS" >&2; exit 1; }

# sri FILE: the SRI hash of FILE in SHA256SUMS.
sri() {
    local hex
    hex="$(grep -E "[ /]$1\$" <<<"$sums" | awk '{print $1}')"
    [ "${#hex}" -eq 64 ] || { echo "no sha256 for $1 in $base/SHA256SUMS" >&2; exit 1; }
    nix hash convert --hash-algo sha256 --to sri "$hex"
}

jq -n --arg version "$version" \
    --arg arm "$(sri "drive-$version-aarch64-apple-darwin.tar.gz")" \
    --arg x86 "$(sri "drive-$version-x86_64-apple-darwin.tar.gz")" \
    --arg armApp "$(sri "Drive-$version-aarch64-apple-darwin.zip")" \
    --arg x86App "$(sri "Drive-$version-x86_64-apple-darwin.zip")" \
    '{version: $version,
      hashes: {"aarch64-apple-darwin": $arm, "x86_64-apple-darwin": $x86},
      apps: {"aarch64-apple-darwin": $armApp, "x86_64-apple-darwin": $x86App}}' \
    >"$here/source.json"
echo "drive-release: $version"
