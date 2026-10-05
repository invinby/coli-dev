"""Bound ASGI request-body memory use before FastAPI parses request JSON."""

from __future__ import annotations

import json
from typing import Any


class RequestBodyLimitMiddleware:
    """Buffer and replay bounded request bodies, including chunked requests."""

    def __init__(self, app: Any, max_bytes: int) -> None:
        if max_bytes < 1:
            raise ValueError("max_bytes must be positive")
        self.app = app
        self.max_bytes = max_bytes

    async def _respond(self, send, status: int, detail: str) -> None:
        body = json.dumps({"detail": detail}).encode("utf-8")
        await send({
            "type": "http.response.start",
            "status": status,
            "headers": [
                (b"content-type", b"application/json"),
                (b"content-length", str(len(body)).encode("ascii")),
            ],
        })
        await send({"type": "http.response.body", "body": body})

    async def __call__(self, scope, receive, send) -> None:
        if scope.get("type") != "http":
            await self.app(scope, receive, send)
            return

        content_lengths = [
            value for name, value in scope.get("headers", [])
            if name.lower() == b"content-length"
        ]
        if len(content_lengths) > 1:
            await self._respond(send, 400, "Invalid Content-Length")
            return

        declared_length: int | None = None
        if content_lengths:
            try:
                raw_length = content_lengths[0].decode("ascii")
                if not raw_length.isdecimal():
                    raise ValueError
                declared_length = int(raw_length)
            except (UnicodeDecodeError, ValueError):
                await self._respond(send, 400, "Invalid Content-Length")
                return
            if declared_length > self.max_bytes:
                await self._respond(send, 413, "Request body is too large")
                return

        messages: list[dict[str, Any]] = []
        total_bytes = 0
        while True:
            message = await receive()
            if message["type"] == "http.disconnect":
                return
            if message["type"] != "http.request":
                continue
            total_bytes += len(message.get("body", b""))
            if total_bytes > self.max_bytes:
                await self._respond(send, 413, "Request body is too large")
                return
            messages.append(message)
            if not message.get("more_body", False):
                break

        if declared_length is not None and declared_length != total_bytes:
            await self._respond(send, 400, "Content-Length does not match request body")
            return

        next_message = 0

        async def replay_receive():
            nonlocal next_message
            if next_message < len(messages):
                message = messages[next_message]
                next_message += 1
                return message
            return await receive()

        await self.app(scope, replay_receive, send)
