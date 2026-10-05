from __future__ import annotations

import asyncio
from unittest.mock import AsyncMock, call

import pytest

from obsidian_worker import ObsidianWorker


@pytest.mark.parametrize(
    "path",
    [
        "/outside.md",
        "../outside.md",
        "lessons/../../outside.md",
        r"lessons\..\outside.md",
        "%2e%2e/outside.md",
        "%252e%252e%252foutside.md",
        "%2Fetc%2Fpasswd",
        r"C:\outside.md",
        "lesson\x00.md",
        "x" * 1025,
    ],
)
def test_vault_paths_reject_absolute_traversal_and_control_inputs(path: str) -> None:
    with pytest.raises(ValueError, match="Invalid Obsidian vault path"):
        ObsidianWorker._vault_path(path)


def test_vault_paths_encode_url_delimiters_and_allow_root_listing() -> None:
    safe = ObsidianWorker._vault_path("Course notes/Биология #1?.md")

    assert safe == "Course%20notes/%D0%91%D0%B8%D0%BE%D0%BB%D0%BE%D0%B3%D0%B8%D1%8F%20%231%3F.md"
    assert ObsidianWorker._vault_path("", allow_root=True) == ""
    with pytest.raises(ValueError, match="Invalid Obsidian vault path"):
        ObsidianWorker._vault_path("")


@pytest.mark.parametrize(
    "url",
    [
        "https://vault.example/api",
        "http://192.168.1.25:27123",
        "http://127.0.0.1.evil.example:27123",
        "http://user:password@127.0.0.1:27123",
    ],
)
def test_worker_drops_non_loopback_endpoints_before_sending_bearer_tokens(url: str) -> None:
    worker = ObsidianWorker(base_url=url, api_key="must-never-leave-localhost")

    async def exercise() -> None:
        assert await worker.ping() is False
        await worker.close()

    asyncio.run(exercise())

    assert worker._candidates == []
    assert worker.last_error == "Obsidian URL must use localhost or a loopback IP"


def test_obsidian_file_operations_use_encoded_vault_relative_paths() -> None:
    worker = ObsidianWorker(base_url="http://127.0.0.1:27123", api_key="test-only")
    request = AsyncMock(side_effect=[
        {"content": "lesson"},
        {"ok": True},
        {"ok": True},
        {"files": ["lesson.md"]},
    ])
    worker._request = request  # type: ignore[method-assign]

    async def exercise() -> None:
        await worker.read("Course notes/Lesson #1?.md")
        await worker.write("Course notes/Lesson #1?.md", "content")
        await worker.delete("Course notes/Lesson #1?.md")
        files = await worker.list_files("")
        assert files == ["lesson.md"]
        await worker.close()

    asyncio.run(exercise())

    encoded_path = "Course%20notes/Lesson%20%231%3F.md"
    assert request.await_args_list == [
        call("GET", f"vault/{encoded_path}"),
        call("PUT", f"vault/{encoded_path}", content="content", headers={"Content-Type": "text/markdown"}),
        call("DELETE", f"vault/{encoded_path}"),
        call("GET", "vault/"),
    ]
