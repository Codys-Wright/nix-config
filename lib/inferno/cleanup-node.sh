#!/usr/bin/env bash
set -euo pipefail
wanted="$1"
current=""
/run/current-system/sw/bin/pw-cli ls Node | while IFS= read -r node_line; do
  case "$node_line" in
    id\ *)
      current=$(printf '%s\n' "$node_line" | /run/current-system/sw/bin/awk '{gsub(/,/, "", $2); print $2}')
      ;;
    *"node.name = \"$wanted\""*)
      if [ -n "$current" ]; then
        /run/current-system/sw/bin/pw-cli destroy "$current" || true
      fi
      ;;
  esac
done
