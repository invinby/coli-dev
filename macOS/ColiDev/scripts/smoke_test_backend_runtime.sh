#!/usr/bin/env bash
set -euo pipefail

app_bundle="${1:?usage: smoke_test_backend_runtime.sh /path/to/ColiDev.app}"
resources="$app_bundle/Contents/Resources"
executable="$resources/ColiDevBackend/ColiDevBackend"
test -x "$executable"
test -s "$resources/02_Areas/Mathematics/curriculum.md"

smoke_root="$(mktemp -d "${TMPDIR:-/tmp}/colidev-backend-smoke.XXXXXX")"
mkdir -p "$smoke_root/data" "$smoke_root/logs"
port=18763
COLIDEV_PROJECT_ROOT="$resources" \
COLIDEV_DATA_DIR="$smoke_root/data" \
COLIDEV_LOG_DIR="$smoke_root/logs" \
HOST=127.0.0.1 \
PORT="$port" \
DEV_MODE=false \
NET_CHECK_TIMEOUT=0.5 \
"$executable" >"$smoke_root/backend.log" 2>&1 &
backend_pid=$!

cleanup() {
    if kill -0 "$backend_pid" 2>/dev/null; then
        kill "$backend_pid" 2>/dev/null || true
        wait "$backend_pid" 2>/dev/null || true
    fi
    if [[ "${KEEP_COLIDEV_SMOKE_LOGS:-0}" != "1" ]]; then
        rm -rf "$smoke_root"
    else
        echo "Backend smoke logs: $smoke_root"
    fi
}
trap cleanup EXIT

ready=0
deadline=$((SECONDS + 30))
while (( SECONDS < deadline )); do
    if curl --silent --show-error --fail --max-time 2 "http://127.0.0.1:$port/api/status" \
        --output "$smoke_root/status.json" 2>/dev/null; then
        ready=1
        break
    fi
    if ! kill -0 "$backend_pid" 2>/dev/null; then
        cat "$smoke_root/backend.log" >&2
        echo "Bundled backend exited before becoming ready" >&2
        exit 1
    fi
    sleep 0.25
done

if [[ "$ready" != "1" ]]; then
    cat "$smoke_root/backend.log" >&2
    echo "Bundled backend did not become ready in 30 seconds" >&2
    exit 1
fi

grep -Eq '"service"[[:space:]]*:[[:space:]]*"coli-dev Orchestrator' "$smoke_root/status.json"
curl --silent --show-error --fail --max-time 5 "http://127.0.0.1:$port/learning/progress" \
    --output "$smoke_root/progress.json"
curl --silent --show-error --fail --max-time 5 "http://127.0.0.1:$port/" \
    | grep -qi 'ColiDev'
echo "Bundled backend API, progress store, and tutor page responded successfully"
