# llm — drive this host's llama-server router (fleet.ai.llama-server).
# Body of a writeShellApplication (strict mode, PATH set by Nix).

url="${LLM_URL:-$LLM_DEFAULT_URL}"
if [ "${1:-}" = "-H" ] || [ "${1:-}" = "--host" ]; then
  url="http://$2:${LLM_PORT:-8012}"
  shift 2
fi

usage() {
  cat <<EOF
usage: llm [-H host] <command> [args]

  ls                       models in the cache, with load status
  pull <repo>[:<quant>]    download a Hugging Face GGUF (e.g. unsloth/gpt-oss-20b-GGUF:Q4_K_M)
  rm <model>               delete a model from the cache
  load|unload <model>      load or unload a model
  chat <model> [prompt]    one-shot chat (prompt from stdin if omitted), prints tokens/s
  bench <model>... [-- llama-bench args]
                           unload everything, then llama-bench each model (this host only)
  url                      the OpenAI base URL to give clients

Models are named by their 'llm ls' id. -H talks to another host (port \$LLM_PORT, default 8012).
EOF
}

json() { jq -nc --arg m "$1" '{model: $m}'; }
post() { curl --fail-with-body -sS -X POST -H 'Content-Type: application/json' -d "$2" "$url$1"; }
uri() { jq -rn --arg m "$1" '$m | @uri'; }
models() { curl --fail-with-body -sS "$url/models"; }

pull() {
  local model="$1" sse sse_pid
  sse=$(mktemp)
  curl -sN "$url/models/sse" >"$sse" &
  sse_pid=$!
  # shellcheck disable=SC2064
  trap "kill $sse_pid 2>/dev/null; rm -f '$sse'" EXIT
  sleep 0.5
  post /models "$(json "$model")" >/dev/null
  echo "downloading $model ..."
  tail -n +1 -f --pid="$sse_pid" "$sse" | while IFS= read -r line; do
    case "$line" in
      data:*) ;;
      *) continue ;;
    esac
    ev=$(jq -c --arg m "$model" 'select(.model == $m)' <<<"${line#data: }" 2>/dev/null || true)
    [ -n "$ev" ] || continue
    case "$(jq -r .event <<<"$ev")" in
      download_finished)
        kill "$sse_pid"
        printf "\ndone\n"
        exit 0
        ;;
      download_failed)
        kill "$sse_pid"
        echo "download failed: $(jq -c .data <<<"$ev")" >&2
        exit 1
        ;;
      download_progress)
        printf '\r%s' "$(jq -r '[.data.progress[]] | (map(.done) | add) as $d | (map(.total) | add) as $t
          | "\($d / 1e9 * 10 | floor / 10) / \($t / 1e9 * 10 | floor / 10) GB (\(if $t > 0 then $d * 100 / $t | floor else 0 end)%)"' <<<"$ev")"
        ;;
    esac
  done
  models >/dev/null # refresh the router's model list
}

# The cached GGUF for owner/repo[:quant] (Hugging Face hub layout under
# $LLAMA_CACHE; first shard of split models; any GGUF without a quant).
gguf() {
  local repo="${1%%:*}" quant=""
  [ "$repo" = "$1" ] || quant="${1#*:}"
  find "${LLAMA_CACHE:-/var/cache/llama-cpp}/models--${repo//\//--}/snapshots" ! -name 'mmproj*' \
    \( -iname "*${quant}.gguf" -o -iname "*${quant}-00001-of-*.gguf" \) 2>/dev/null | sort | head -n1
}

bench() {
  local paths=() extra=() m p
  while [ "$#" -gt 0 ]; do
    if [ "$1" = "--" ]; then
      shift
      extra=("$@")
      break
    fi
    p=$(gguf "$1")
    [ -n "$p" ] || {
      echo "no cached model '$1' (see llm ls)" >&2
      exit 1
    }
    paths+=(-m "$p")
    shift
  done
  [ "${#paths[@]}" -gt 0 ] || {
    usage
    exit 1
  }
  # Free the GPU: the router keeps the last model resident. (Not downloads:
  # unloading a downloading model cancels it.)
  for m in $(models | jq -r '.data[] | select(.status.value | IN("loaded", "loading", "sleeping")) | .id'); do
    post /models/unload "$(json "$m")" >/dev/null || true
  done
  sleep 2
  [ "${#extra[@]}" -gt 0 ] || extra=(-p 512 -n 128 -ngl 99 -fa 1)
  llama-bench "${paths[@]}" "${extra[@]}"
}

chat() {
  local model="$1" prompt
  shift
  if [ "$#" -gt 0 ]; then prompt="$*"; else prompt=$(cat); fi
  post /v1/chat/completions "$(jq -nc --arg m "$model" --arg p "$prompt" \
    '{model: $m, messages: [{role: "user", content: $p}]}')" |
    jq -r '.choices[0].message.content,
      "\n-- \(.timings.prompt_n) prompt tok @ \(.timings.prompt_per_second | floor) t/s, \(.timings.predicted_n) gen tok @ \(.timings.predicted_per_second | floor) t/s"'
}

need() {
  [ "$1" -ge "$2" ] || {
    usage
    exit 1
  }
}

cmd="${1:-}"
[ "$#" -gt 0 ] && shift
case "$cmd" in
  ls) models | jq -r '.data[] | "\(.status.value // "?")\t\(.id)"' | sort ;;
  pull)
    need "$#" 1
    pull "$1"
    ;;
  rm)
    need "$#" 1
    curl --fail-with-body -sS -X DELETE "$url/models?model=$(uri "$1")"
    echo
    ;;
  load | unload)
    need "$#" 1
    post "/models/$cmd" "$(json "$1")"
    echo
    ;;
  chat)
    need "$#" 1
    chat "$@"
    ;;
  bench) bench "$@" ;;
  url) echo "$url/v1" ;;
  *)
    usage
    [ -z "$cmd" ] || exit 1
    ;;
esac
