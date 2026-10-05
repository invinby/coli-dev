from __future__ import annotations

import asyncio
import os
import sys

import pytest
from pydantic import ValidationError

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from orchestrator import ChatRequest, ObsidianSearchRequest, ObsidianWriteRequest
from request_limits import RequestBodyLimitMiddleware


def _run_middleware(chunks: list[dict], *, max_bytes: int, headers: list[tuple[bytes, bytes]] | None = None):
    incoming = iter(chunks)
    sent: list[dict] = []
    calls = {"app": 0, "body": b""}

    async def receive():
        return next(incoming, {"type": "http.disconnect"})

    async def send(message):
        sent.append(message)

    async def app(scope, receive, send):
        calls["app"] += 1
        body = bytearray()
        while True:
            message = await receive()
            if message["type"] != "http.request":
                break
            body.extend(message.get("body", b""))
            if not message.get("more_body", False):
                break
        calls["body"] = bytes(body)
        await send({"type": "http.response.start", "status": 200, "headers": []})
        await send({"type": "http.response.body", "body": b"ok"})

    scope = {
        "type": "http",
        "method": "POST",
        "path": "/chat/stream",
        "headers": headers or [],
    }
    middleware = RequestBodyLimitMiddleware(app, max_bytes=max_bytes)
    asyncio.run(middleware(scope, receive, send))
    return sent, calls


def test_declared_oversized_request_is_rejected_before_body_parsing() -> None:
    body = b"x" * 11
    sent, calls = _run_middleware(
        [{"type": "http.request", "body": body, "more_body": False}],
        max_bytes=10,
        headers=[(b"content-length", b"11")],
    )

    assert sent[0]["status"] == 413
    assert calls["app"] == 0


def test_chunked_request_cannot_exceed_limit() -> None:
    sent, calls = _run_middleware(
        [
            {"type": "http.request", "body": b"123456", "more_body": True},
            {"type": "http.request", "body": b"789", "more_body": False},
        ],
        max_bytes=8,
    )

    assert sent[0]["status"] == 413
    assert calls["app"] == 0


def test_bounded_chunked_request_is_replayed_intact() -> None:
    sent, calls = _run_middleware(
        [
            {"type": "http.request", "body": b"hello ", "more_body": True},
            {"type": "http.request", "body": b"world", "more_body": False},
        ],
        max_bytes=11,
    )

    assert sent[0]["status"] == 200
    assert calls == {"app": 1, "body": b"hello world"}


def test_declared_length_mismatch_is_rejected() -> None:
    sent, calls = _run_middleware(
        [{"type": "http.request", "body": b"short", "more_body": False}],
        max_bytes=20,
        headers=[(b"content-length", b"8")],
    )

    assert sent[0]["status"] == 400
    assert calls["app"] == 0


@pytest.mark.parametrize(
    "payload",
    [
        {"message": "x" * 64_001},
        {"message": "ok", "system_prompt": "x" * 32_001},
        {"message": "ok", "retrieval_query": "x" * 16_001},
        {"message": "ok", "model": "x" * 129},
    ],
)
def test_chat_request_fields_have_limits(payload: dict) -> None:
    with pytest.raises(ValidationError):
        ChatRequest(**payload)


def test_obsidian_payload_fields_have_limits() -> None:
    with pytest.raises(ValidationError):
        ObsidianWriteRequest(content="x" * 950_001)
    with pytest.raises(ValidationError):
        ObsidianSearchRequest(query="x" * 4_097)
