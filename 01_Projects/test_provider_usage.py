from __future__ import annotations

import asyncio
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timedelta, timezone
from decimal import Decimal
import json
from pathlib import Path
import sys
import threading

import httpx
import pytest

sys.path.insert(0, str(Path(__file__).parent))

import orchestrator
import provider_usage
from provider_usage import (
    ProviderUsageStore,
    TokenUsage,
    gemini_usage,
    ollama_usage,
    openai_compatible_usage,
)


@pytest.mark.parametrize(
    ("parser", "payload", "expected"),
    [
        (openai_compatible_usage, {"prompt_tokens": 12, "completion_tokens": 7}, TokenUsage(12, 7, 19)),
        (
            openai_compatible_usage,
            {"prompt_tokens": 12, "completion_tokens": 7, "total_tokens": 22},
            TokenUsage(12, 7, 22),
        ),
        (
            gemini_usage,
            {"promptTokenCount": 13, "candidatesTokenCount": 8, "totalTokenCount": 25},
            TokenUsage(13, 8, 25),
        ),
        (ollama_usage, {"prompt_eval_count": 4, "eval_count": 9}, TokenUsage(4, 9, 13)),
        (openai_compatible_usage, {"prompt_tokens": True, "completion_tokens": -1}, TokenUsage()),
        (gemini_usage, None, TokenUsage()),
        (ollama_usage, {"prompt_eval_count": "8"}, TokenUsage()),
    ],
)
def test_provider_parsers_keep_only_valid_reported_counters(parser, payload, expected):
    assert parser(payload) == expected


def test_openrouter_usage_parser_keeps_reported_dollar_cost_exact():
    parser = getattr(provider_usage, "openrouter_usage", None)
    assert callable(parser)

    usage = parser({
        "prompt_tokens": 120,
        "completion_tokens": 80,
        "total_tokens": 200,
        "cost": 0.00000123,
    })

    assert usage.input_tokens == 120
    assert usage.output_tokens == 80
    assert usage.total_tokens == 200
    assert usage.cost_usd == Decimal("0.00000123")


@pytest.mark.parametrize("invalid_cost", [True, -0.1, float("nan"), float("inf"), "0.2"])
def test_openrouter_usage_parser_does_not_treat_invalid_cost_as_reported(invalid_cost):
    parser = getattr(provider_usage, "openrouter_usage", None)
    assert callable(parser)

    usage = parser({"prompt_tokens": 3, "completion_tokens": 2, "cost": invalid_cost})

    assert usage.cost_usd is None


def test_openrouter_usage_parser_normalizes_negative_zero_cost():
    parser = getattr(provider_usage, "openrouter_usage", None)
    assert callable(parser)

    usage = parser({"cost": -0.0})

    assert usage.cost_usd == Decimal("0")
    assert str(usage.cost_usd) == "0"


def test_summary_sums_only_provider_reported_cost_and_keeps_unknown_separate(tmp_path):
    parser = getattr(provider_usage, "openrouter_usage", None)
    assert callable(parser)
    store = ProviderUsageStore(tmp_path / "provider-usage.sqlite3")
    store.record(
        "openrouter",
        "openai/gpt-test",
        "openai-compatible",
        parser({"prompt_tokens": 120, "completion_tokens": 80, "cost": 0.00000123}),
    )
    store.record("gemini", "gemini-flash", "gemini", TokenUsage(10, 5, 15))

    summary = store.summary(days=1)

    assert summary["totals"]["reported_cost_usd"] == "0.00000123"
    assert summary["totals"]["responses_with_reported_cost"] == 1
    assert summary["totals"]["responses_without_reported_cost"] == 1
    openrouter = next(row for row in summary["providers"] if row["provider"] == "openrouter")
    gemini = next(row for row in summary["providers"] if row["provider"] == "gemini")
    assert openrouter["reported_cost_usd"] == "0.00000123"
    assert gemini["reported_cost_usd"] is None


def test_summary_groups_responses_and_marks_missing_provider_usage(tmp_path):
    store = ProviderUsageStore(tmp_path / "provider-usage.sqlite3")
    store.initialize()
    store.record("gemini", "gemini-flash", "gemini", TokenUsage(10, 5, 15))
    store.record("gemini", "gemini-flash", "gemini", TokenUsage())
    store.record("ollama", "qwen-local", "ollama", TokenUsage(4, 6, 10))

    result = store.summary(days=1)

    assert result["period_days"] == 1
    assert result["totals"] == {
        "successful_responses": 3,
        "responses_with_reported_usage": 2,
        "responses_without_reported_usage": 1,
        "input_tokens": 14,
        "output_tokens": 11,
        "total_tokens": 25,
        "responses_with_input_count": 2,
        "responses_with_output_count": 2,
        "responses_with_total_count": 2,
        "responses_with_reported_cost": 0,
        "responses_without_reported_cost": 3,
        "reported_cost_usd": None,
    }
    assert result["providers"][0]["provider"] == "gemini"
    assert result["providers"][0]["responses_without_reported_usage"] == 1
    assert "Missing counters or costs are not estimated" in result["note"]


def test_summary_uses_utc_window_and_excludes_older_events(tmp_path):
    now = [datetime(2026, 10, 5, 12, tzinfo=timezone.utc)]
    store = ProviderUsageStore(tmp_path / "usage.sqlite3", clock=lambda: now[0], retention_days=90)
    store.record("kimi", "kimi-model", "openai-compatible", TokenUsage(3, 2, 5))
    now[0] += timedelta(days=1)
    store.record("kimi", "kimi-model", "openai-compatible", TokenUsage(7, 1, 8))

    one_day = store.summary(days=1)
    two_days = store.summary(days=2)

    assert one_day["totals"]["total_tokens"] == 8
    assert one_day["totals"]["successful_responses"] == 1
    assert two_days["totals"]["total_tokens"] == 13
    assert two_days["totals"]["successful_responses"] == 2


def test_store_prunes_usage_metadata_after_configured_retention(tmp_path):
    now = [datetime(2026, 10, 1, 12, tzinfo=timezone.utc)]
    store = ProviderUsageStore(
        tmp_path / "usage.sqlite3",
        clock=lambda: now[0],
        retention_days=3,
    )
    store.record("ollama", "qwen-local", "ollama", TokenUsage(2, 3, 5))
    now[0] += timedelta(days=4)
    store.record("ollama", "qwen-local", "ollama", TokenUsage(7, 1, 8))

    result = store.summary(days=3)

    assert result["totals"]["successful_responses"] == 1
    assert result["totals"]["total_tokens"] == 8


def test_model_metadata_rejects_text_instead_of_persisting_it(tmp_path):
    store = ProviderUsageStore(tmp_path / "usage.sqlite3")
    store.record(
        "openrouter",
        "free/provider:v1 private prompt text",
        "openai-compatible",
        TokenUsage(1, 2, 3),
    )

    result = store.summary(days=1)

    assert result["providers"][0]["model"] == "unknown"
    assert "private" not in str(result)


@pytest.mark.parametrize(
    ("provider", "model", "usage_format", "usage"),
    [
        ("unknown", "model", "gemini", TokenUsage()),
        ("gemini", "model", "unknown", TokenUsage()),
        ("gemini", "model", "gemini", {"total_tokens": 1}),
        ("gemini", "model", "gemini", TokenUsage(-1, 0, 0)),
        ("gemini", "model", "gemini", TokenUsage(True, 0, 1)),
        ("gemini", "model", "gemini", TokenUsage(2**63, 0, 2**63)),
    ],
)
def test_record_rejects_invalid_metadata(tmp_path, provider, model, usage_format, usage):
    store = ProviderUsageStore(tmp_path / "usage.sqlite3")

    with pytest.raises(ValueError):
        store.record(provider, model, usage_format, usage)


def test_store_persists_only_usage_metadata_without_content_columns(tmp_path):
    import sqlite3

    path = tmp_path / "usage.sqlite3"
    store = ProviderUsageStore(path)
    store.record("openrouter", "chosen model", "openai-compatible", TokenUsage(1, 2, 3))

    with sqlite3.connect(path) as connection:
        columns = {
            row[1] for row in connection.execute("PRAGMA table_info(provider_usage_events)")
        }

    assert columns == {
        "event_id", "occurred_at", "provider", "model", "usage_format",
        "input_tokens", "output_tokens", "total_tokens", "usage_reported",
        "reported_cost_usd",
    }


def test_existing_usage_store_migrates_for_provider_reported_cost(tmp_path):
    import sqlite3

    path = tmp_path / "provider-usage.sqlite3"
    old_event_time = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
    with sqlite3.connect(path) as connection:
        connection.execute(
            """CREATE TABLE provider_usage_events (
                event_id TEXT PRIMARY KEY,
                occurred_at TEXT NOT NULL,
                provider TEXT NOT NULL,
                model TEXT NOT NULL,
                usage_format TEXT NOT NULL,
                input_tokens INTEGER,
                output_tokens INTEGER,
                total_tokens INTEGER,
                usage_reported INTEGER NOT NULL
            )"""
        )
        connection.execute(
            """INSERT INTO provider_usage_events (
                event_id, occurred_at, provider, model, usage_format,
                input_tokens, output_tokens, total_tokens, usage_reported
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            ("legacy", old_event_time, "gemini", "legacy-model", "gemini", 2, 3, 5, 1),
        )

    store = ProviderUsageStore(path)
    store.initialize()

    with sqlite3.connect(path) as connection:
        columns = {
            row[1] for row in connection.execute("PRAGMA table_info(provider_usage_events)")
        }
    assert "reported_cost_usd" in columns

    result = store.summary(days=1)
    assert result["totals"]["successful_responses"] == 1
    assert result["totals"]["total_tokens"] == 5
    assert result["totals"]["reported_cost_usd"] is None


def test_store_records_custom_openai_compatible_provider_usage(tmp_path):
    store = ProviderUsageStore(tmp_path / "usage.sqlite3")
    store.record("compatible", "custom/model", "openai-compatible", TokenUsage(9, 4, 13))

    result = store.summary(days=1)

    assert result["totals"]["total_tokens"] == 13
    assert result["providers"][0]["provider"] == "compatible"


def test_cloud_call_budget_counts_attempts_and_blocks_after_limit(tmp_path):
    store = ProviderUsageStore(tmp_path / "usage.sqlite3")

    first = store.reserve_cloud_call("openrouter", "openrouter/free", 2)
    second = store.reserve_cloud_call("gemini", "gemini-flash", 2)
    blocked = store.reserve_cloud_call("kimi", "kimi-model", 2)

    assert first == {"allowed": True, "used": 1, "limit": 2, "remaining": 1}
    assert second == {"allowed": True, "used": 2, "limit": 2, "remaining": 0}
    assert blocked == {"allowed": False, "used": 2, "limit": 2, "remaining": 0}
    assert store.cloud_call_status(2) == {"used": 2, "limit": 2, "remaining": 0}


def test_zero_cloud_call_limit_blocks_without_recording_an_attempt(tmp_path):
    store = ProviderUsageStore(tmp_path / "usage.sqlite3")

    blocked = store.reserve_cloud_call("openrouter", "openrouter/free", 0)

    assert blocked == {"allowed": False, "used": 0, "limit": 0, "remaining": 0}
    assert store.cloud_call_status(0) == {"used": 0, "limit": 0, "remaining": 0}


def test_cloud_call_budget_is_atomic_under_concurrent_requests(tmp_path):
    store = ProviderUsageStore(tmp_path / "usage.sqlite3")

    with ThreadPoolExecutor(max_workers=12) as executor:
        results = list(executor.map(
            lambda index: store.reserve_cloud_call("openrouter", f"model-{index}", 5),
            range(20),
        ))

    assert sum(result["allowed"] for result in results) == 5
    assert store.cloud_call_status(5) == {"used": 5, "limit": 5, "remaining": 0}


def test_cloud_call_reservation_uses_time_after_entering_the_serialized_section(tmp_path):
    older_request_captured_time = threading.Event()
    newer_request_captured_time = threading.Event()
    release_older_request = threading.Event()
    earlier = datetime(2026, 10, 5, 12, 0, 0, tzinfo=timezone.utc)
    later = datetime(2026, 10, 5, 12, 0, 1, tzinfo=timezone.utc)

    def clock():
        if threading.current_thread().name.endswith("_0"):
            older_request_captured_time.set()
            assert release_older_request.wait(timeout=5)
            return earlier
        newer_request_captured_time.set()
        return later

    store = ProviderUsageStore(tmp_path / "usage.sqlite3", clock=clock)
    with ThreadPoolExecutor(max_workers=2, thread_name_prefix="cloud-budget") as executor:
        older_request = executor.submit(
            store.reserve_cloud_call, "openrouter", "older", 1
        )
        assert older_request_captured_time.wait(timeout=2)

        newer_request = executor.submit(
            store.reserve_cloud_call, "openrouter", "newer", 1
        )
        # Before the fix, timestamps were captured outside the lock, allowing this
        # later request to reserve first while the older timestamp was waiting.
        if newer_request_captured_time.wait(timeout=1):
            assert newer_request.result(timeout=2)["allowed"] is True

        release_older_request.set()
        results = [older_request.result(timeout=3), newer_request.result(timeout=3)]

    assert sum(result["allowed"] for result in results) == 1
    assert store.cloud_call_status(1) == {"used": 1, "limit": 1, "remaining": 0}


def test_cloud_call_budget_resets_at_next_utc_day(tmp_path):
    now = [datetime(2026, 10, 5, 23, 59, tzinfo=timezone.utc)]
    store = ProviderUsageStore(tmp_path / "usage.sqlite3", clock=lambda: now[0])
    store.reserve_cloud_call("gemini", "gemini-flash", 1)
    now[0] += timedelta(minutes=2)

    assert store.cloud_call_status(1) == {"used": 0, "limit": 1, "remaining": 1}
    assert store.reserve_cloud_call("gemini", "gemini-flash", 1)["allowed"] is True


def test_model_adapter_blocks_outbound_request_after_call_budget_is_used(tmp_path, monkeypatch):
    store = ProviderUsageStore(tmp_path / "usage.sqlite3")
    policy_store = orchestrator.AutoCostPolicyStore(tmp_path / "cost-policy.json")
    policy_store.set(False, daily_cloud_call_limit=1)
    monkeypatch.setattr(orchestrator, "provider_usage_store", store)
    monkeypatch.setattr(orchestrator, "auto_cost_policy", policy_store)
    monkeypatch.setattr(orchestrator, "OPENROUTER_KEY", "test-key")
    outbound_requests = []

    def handler(request: httpx.Request) -> httpx.Response:
        outbound_requests.append(request)
        return httpx.Response(200, json={
            "model": "free/example",
            "choices": [{"message": {"content": "reply"}}],
            "usage": {"prompt_tokens": 1, "completion_tokens": 1, "total_tokens": 2},
        }, request=request)

    async def exercise() -> list[str]:
        async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as client:
            engine = orchestrator.ConsiliumEngine(client, "en", client)
            return [
                await engine._ask_openrouter("question", "system", "test"),
                await engine._ask_openrouter("question", "system", "test"),
            ]

    replies = asyncio.run(exercise())

    assert replies[0] == "reply"
    assert "Daily cloud model call limit reached (1/1)" in replies[1]
    assert len(outbound_requests) == 1
    assert store.cloud_call_status(1) == {"used": 1, "limit": 1, "remaining": 0}


def test_zero_daily_cloud_limit_stops_openrouter_before_network(tmp_path, monkeypatch):
    usage_store = ProviderUsageStore(tmp_path / "usage.sqlite3")
    policy_store = orchestrator.AutoCostPolicyStore(tmp_path / "cost-policy.json")
    policy_store.set(False, daily_cloud_call_limit=0)
    monkeypatch.setattr(orchestrator, "provider_usage_store", usage_store)
    monkeypatch.setattr(orchestrator, "auto_cost_policy", policy_store)
    monkeypatch.setattr(orchestrator, "OPENROUTER_KEY", "test-key")
    outbound_requests = []

    def handler(request: httpx.Request) -> httpx.Response:
        outbound_requests.append(request)
        return httpx.Response(500, request=request)

    async def exercise() -> str:
        async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as client:
            engine = orchestrator.ConsiliumEngine(client, "en", client)
            return await engine._ask_openrouter(
                "question", "system", "test", model="openrouter/free"
            )

    reply = asyncio.run(exercise())

    assert reply == "[Daily cloud model call limit reached (0/0)]"
    assert outbound_requests == []
    assert usage_store.cloud_call_status(0) == {"used": 0, "limit": 0, "remaining": 0}


@pytest.mark.parametrize(
    ("provider", "limit"),
    [("ollama", 1), ("unknown", 1), ("gemini", -1), ("gemini", True)],
)
def test_cloud_call_budget_rejects_invalid_arguments(tmp_path, provider, limit):
    store = ProviderUsageStore(tmp_path / "usage.sqlite3")

    with pytest.raises(ValueError):
        store.reserve_cloud_call(provider, "model", limit)


def test_concurrent_records_are_not_lost(tmp_path):
    store = ProviderUsageStore(tmp_path / "usage.sqlite3")
    store.initialize()

    with ThreadPoolExecutor(max_workers=8) as executor:
        list(executor.map(
            lambda index: store.record(
                "ollama", "local", "ollama", TokenUsage(index, 1, index + 1)
            ),
            range(40),
        ))

    totals = store.summary(days=1)["totals"]
    assert totals["successful_responses"] == 40
    assert totals["input_tokens"] == sum(range(40))
    assert totals["total_tokens"] == sum(range(1, 41))


@pytest.mark.parametrize("days", [0, -1, 91, True, 1.5])
def test_summary_rejects_invalid_windows(tmp_path, days):
    with pytest.raises(ValueError):
        ProviderUsageStore(tmp_path / "usage.sqlite3").summary(days=days)


def test_model_adapters_record_provider_reported_usage_without_messages(tmp_path, monkeypatch):
    store = ProviderUsageStore(tmp_path / "usage.sqlite3")
    monkeypatch.setattr(orchestrator, "provider_usage_store", store)
    monkeypatch.setattr(orchestrator, "KIMI_KEY", "test-key")
    monkeypatch.setattr(orchestrator, "OPENROUTER_KEY", "test-key")
    monkeypatch.setattr(orchestrator, "GEMINI_KEY", "test-key")
    monkeypatch.setattr(orchestrator, "OLLAMA_BASE", "http://127.0.0.1:11434")
    monkeypatch.setattr(orchestrator, "OLLAMA_CHAT_URL", "http://127.0.0.1:11434/api/chat")

    def handler(request: httpx.Request) -> httpx.Response:
        if request.url == httpx.URL(orchestrator.KIMI_URL):
            payload = {
                "choices": [{"message": {"content": "kimi answer"}}],
                "usage": {"prompt_tokens": 1, "completion_tokens": 2, "total_tokens": 3},
            }
        elif request.url == httpx.URL(orchestrator.OPENROUTER_URL):
            payload = {
                "model": "free/provider-model:v1",
                "choices": [{"message": {"content": "router answer"}}],
                "usage": {"prompt_tokens": 3, "completion_tokens": 4, "total_tokens": 7},
            }
        elif request.url == httpx.URL(orchestrator.GEMINI_FLASH_URL):
            payload = {
                "candidates": [{"content": {"parts": [{"text": "Gemini answer"}]}}],
                "usageMetadata": {
                    "promptTokenCount": 5,
                    "candidatesTokenCount": 6,
                    "totalTokenCount": 11,
                },
            }
        else:
            payload = {
                "model": "qwen-local",
                "message": {"content": "local answer"},
                "prompt_eval_count": 7,
                "eval_count": 8,
            }
        return httpx.Response(200, json=payload, request=request)

    async def exercise_adapters() -> list[str]:
        async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as client:
            engine = orchestrator.ConsiliumEngine(client, "en", client)
            return [
                await engine._ask_kimi("private prompt", "private system", "test"),
                await engine._ask_openrouter("private prompt", "private system", "test"),
                await engine._ask_gemini(
                    "private prompt", "private system", orchestrator.GEMINI_FLASH_URL, "test"
                ),
                await engine._ask_ollama("private prompt", "private system", "test"),
            ]

    answers = asyncio.run(exercise_adapters())
    result = store.summary(days=1)

    assert answers == ["kimi answer", "router answer", "Gemini answer", "local answer"]
    assert result["totals"]["successful_responses"] == 4
    assert result["totals"]["responses_with_reported_usage"] == 4
    assert result["totals"]["input_tokens"] == 16
    assert result["totals"]["output_tokens"] == 20
    assert result["totals"]["total_tokens"] == 36
    router = next(row for row in result["providers"] if row["provider"] == "openrouter")
    assert router["model"] == "free/provider-model:v1"
    assert store.cloud_call_status(orchestrator.CLOUD_MODEL_MAX_CALLS_PER_DAY)["used"] == 3


def test_streaming_adapters_record_final_usage_metadata(tmp_path, monkeypatch):
    store = ProviderUsageStore(tmp_path / "usage.sqlite3")
    monkeypatch.setattr(orchestrator, "provider_usage_store", store)
    monkeypatch.setattr(orchestrator, "GEMINI_KEY", "test-key")
    monkeypatch.setattr(orchestrator, "OLLAMA_BASE", "http://127.0.0.1:11434")
    monkeypatch.setattr(orchestrator, "OLLAMA_CHAT_URL", "http://127.0.0.1:11434/api/chat")
    gemini_payload = {
        "candidates": [{
            "content": {"parts": [{"text": "stream answer"}]},
            "finishReason": "STOP",
        }],
        "usageMetadata": {
            "promptTokenCount": 10,
            "candidatesTokenCount": 3,
            "totalTokenCount": 13,
        },
    }
    ollama_events = [
        {"message": {"content": "local "}, "done": False},
        {
            "model": "qwen-stream",
            "done": True,
            "prompt_eval_count": 11,
            "eval_count": 2,
        },
    ]

    def handler(request: httpx.Request) -> httpx.Response:
        if "streamGenerateContent" in str(request.url):
            body = f"data: {json.dumps(gemini_payload)}\n\n"
        else:
            body = "\n".join(json.dumps(event) for event in ollama_events) + "\n"
        return httpx.Response(200, text=body, request=request)

    async def exercise_streams() -> tuple[str, list[str]]:
        async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as client:
            engine = orchestrator.ConsiliumEngine(client, "en", client)
            chunks: list[str] = []

            async def capture(chunk: str) -> None:
                chunks.append(chunk)

            answer = await engine._ask_gemini_streaming(
                "private prompt",
                "private system",
                "https://generativelanguage.googleapis.com/v1beta/models/gemini-test:generateContent",
                "test",
                capture,
            )
            local_chunks = [
                chunk async for chunk in engine._stream_ollama("private prompt", "private system", "test")
            ]
            return answer, chunks + local_chunks

    answer, chunks = asyncio.run(exercise_streams())
    result = store.summary(days=1)

    assert answer == "stream answer"
    assert chunks == ["stream answer", "local "]
    assert result["totals"]["successful_responses"] == 2
    assert result["totals"]["input_tokens"] == 21
    assert result["totals"]["output_tokens"] == 5
    assert result["totals"]["total_tokens"] == 26
    assert store.cloud_call_status(orchestrator.CLOUD_MODEL_MAX_CALLS_PER_DAY)["used"] == 1
