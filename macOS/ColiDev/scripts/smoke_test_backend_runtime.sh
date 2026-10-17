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
    result=$?
    if [[ "$result" -ne 0 ]]; then
        echo "Backend runtime smoke test failed; backend log follows:" >&2
        cat "$smoke_root/backend.log" >&2 2>/dev/null || true
        if [[ -f "$smoke_root/status.json" ]]; then
            echo "Backend status response:" >&2
            cat "$smoke_root/status.json" >&2
        fi
    fi
    if kill -0 "$backend_pid" 2>/dev/null; then
        kill "$backend_pid" 2>/dev/null || true
        wait "$backend_pid" 2>/dev/null || true
    fi
    if [[ "${KEEP_COLIDEV_SMOKE_LOGS:-0}" != "1" ]]; then
        rm -rf "$smoke_root"
    else
        echo "Backend smoke logs: $smoke_root"
    fi
    trap - EXIT
    exit "$result"
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
curl --silent --show-error --fail --max-time 10 -X POST "http://127.0.0.1:$port/knowledge/refresh" \
    --output "$smoke_root/knowledge-refresh.json"
grep -Eq '"status"[[:space:]]*:[[:space:]]*"ok"' "$smoke_root/knowledge-refresh.json"
grep -Eq '"document_count"[[:space:]]*:[[:space:]]*[1-9][0-9]*' "$smoke_root/knowledge-refresh.json"
python3 - "$port" <<'PY'
import json
import sys
from urllib.request import Request, urlopen

base_url = f"http://127.0.0.1:{sys.argv[1]}"

def request_json(path, *, payload=None, method="GET"):
    data = None if payload is None else json.dumps(payload).encode()
    headers = {} if data is None else {"Content-Type": "application/json"}
    request = Request(
        f"{base_url}{path}",
        data=data,
        headers=headers,
        method=method,
    )
    with urlopen(request, timeout=5) as response:
        return json.load(response)


def run(code, values):
    payload = json.dumps({"code": code, "arguments": {"values": values}}).encode()
    request = Request(
        f"{base_url}/practice/python/run",
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urlopen(request, timeout=5) as response:
        return json.load(response)

policy = request_json("/settings/auto-cost-policy")
if policy.get("allow_paid_routes") is not False:
    raise SystemExit("Packaged backend did not default to blocking potentially paid routes")


def require_paid_route_blocked(route, label):
    if (
        route.get("paid_route_blocked") is not True
        or route.get("effective_provider") != "ollama"
        or route.get("status") != "blocked_by_free_only"
    ):
        raise SystemExit(f"Packaged backend did not block the paid {label} route by default")


agent_routes = request_json("/settings/agent-models").get("roles", [])
subject_routes = request_json("/settings/model-routing").get("subjects", [])
if {item.get("role") for item in agent_routes} != {
    "local_draft", "gemini_draft", "critic", "verifier"
}:
    raise SystemExit("Packaged backend did not expose all four configured AI roles")
if {item.get("subject") for item in subject_routes} != {
    "mathematics", "english", "physics", "biology", "zoology", "programming"
}:
    raise SystemExit("Packaged backend did not expose all six configured subject routes")

route_targets = [
    (f"/settings/agent-models/{item['role']}", f"agent role {item['role']}")
    for item in agent_routes
]
route_targets.extend(
    (f"/settings/model-routing/{item['subject']}", f"subject {item['subject']}")
    for item in subject_routes
)
route_targets.append(("/settings/final-synthesis-route", "final synthesis"))

for provider, model, label in (
    ("gemini", "gemini-3.8-flash", "Gemini"),
    ("compatible", "remote-model", "remote OpenAI-compatible"),
):
    if provider == "compatible":
        request_json(
            "/settings/openai-compatible",
            payload={"base_url": "https://api.example.test/v1", "model": model},
            method="PUT",
        )
    for path, target_label in route_targets:
        route = request_json(
            path,
            payload={"provider": provider, "model": model},
            method="PUT",
        )
        require_paid_route_blocked(route, f"{label} {target_label}")

request_json(
    "/settings/openai-compatible",
    payload={"base_url": f"http://127.0.0.1:{sys.argv[1]}/v1", "model": "local-probe"},
    method="PUT",
)
for path, target_label in route_targets:
    route = request_json(
        path,
        payload={"provider": "compatible", "model": "local-probe"},
        method="PUT",
    )
    if (
        route.get("paid_route_blocked") is not False
        or route.get("effective_provider") != "compatible"
    ):
        raise SystemExit(f"Packaged backend blocked the local-compatible {target_label} route")

maximum_code = '''def solve(values):
    if not values:
        raise ValueError("empty input")
    maximum = values[0]
    for value in values:
        if value > maximum:
            maximum = value
    return maximum
'''

if run(maximum_code, [-8, -2, -5]) != {"status": "ok", "result": -2}:
    raise SystemExit("Bundled Python practice returned the wrong negative-list result")
empty_result = run(maximum_code, [])
if empty_result.get("status") != "error" or empty_result.get("code") != "ValueError":
    raise SystemExit("Bundled Python practice did not preserve the empty-input contract")
unsafe_result = run("import os\ndef solve(values):\n    return 1\n", [])
if unsafe_result.get("status") != "error" or unsafe_result.get("code") != "unsupported_syntax":
    raise SystemExit("Bundled Python practice did not reject imports")
print("Bundled backend blocked remote paid routes for every AI role and subject, preserved loopback routes, and kept the Python practice safety contract")
PY
curl --silent --show-error --fail --max-time 5 "http://127.0.0.1:$port/" \
    --output "$smoke_root/tutor.html"
grep -qi 'coli-dev' "$smoke_root/tutor.html"
echo "Bundled backend API, free-only AI policy, progress store, knowledge refresh, Python practice, and tutor page responded successfully"
