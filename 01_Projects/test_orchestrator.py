#!/usr/bin/env python3
"""
test_orchestrator.py — тесты для coli-dev Orchestrator v4.0 (Коворкинг)

Запуск:
    .venv/bin/python -m pytest 01_Projects/test_orchestrator.py -v --tb=long

Или напрямую:
    .venv/bin/python 01_Projects/test_orchestrator.py
"""

from __future__ import annotations

import asyncio
import gc
import json
import os
import sys
from unittest.mock import AsyncMock, MagicMock, patch

import httpx
import psutil
import pytest
from fastapi import HTTPException
from fastapi.testclient import TestClient
from starlette.requests import Request

# ─── Поднимаем проект в sys.path — он в подпапке ───
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import orchestrator  # noqa: E402
from learning_progress import StudyProgressStore  # noqa: E402
from orchestrator import (
    DebateLog,
    SessionTracker,
    app,
    session_tracker,
)

# Константы для тестов
TEST_MSG = "Напиши hello world на Python"
SYSTEM_PROMPT = "You are a test assistant."
FAKE_ANSWER = "print('Hello, world!')"
PROC = psutil.Process(os.getpid())


def _mock_keyring(monkeypatch):
    passwords = {}
    fake = MagicMock()
    fake.get_password.side_effect = lambda service, account: passwords.get((service, account))
    fake.set_password.side_effect = lambda service, account, value: passwords.__setitem__((service, account), value)
    fake.delete_password.side_effect = lambda service, account: passwords.pop((service, account), None)
    monkeypatch.setattr(orchestrator.sys, "platform", "darwin")
    monkeypatch.setattr(orchestrator, "_macos_keychain_backend", lambda: fake)
    return fake, passwords


# ─── Fixtures ──────────────────────────────────────────


@pytest.fixture(autouse=True)
def _reset_session_tracker(monkeypatch, tmp_path):
    """Сброс сессий перед каждым тестом."""
    monkeypatch.setattr(orchestrator, "GEMINI_KEY", "test-gemini-key")
    monkeypatch.setattr(orchestrator, "KIMI_KEY", "test-kimi-key")
    monkeypatch.setattr(orchestrator, "OBSIDIAN_API_KEY", "")
    monkeypatch.setattr(orchestrator, "OBSIDIAN_URL", "http://127.0.0.1:27123")
    monkeypatch.setattr(orchestrator, "OLLAMA_BASE", "http://127.0.0.1:11434")
    monkeypatch.setattr(orchestrator, "OLLAMA_CHAT_URL", "http://127.0.0.1:11434/api/chat")
    monkeypatch.setattr(orchestrator, "_ENV_PROVIDER_VALUES", {
        "GEMINI_API_KEY": "test-gemini-key",
        "KIMI_API_KEY": "test-kimi-key",
        "OBSIDIAN_API_KEY": "",
    })
    monkeypatch.setattr(orchestrator.state, "obsidian", None)
    monkeypatch.setattr(orchestrator.state, "ollama_client", None)
    monkeypatch.setattr(
        orchestrator,
        "study_progress_store",
        StudyProgressStore(tmp_path / "learning-progress.sqlite3"),
    )
    monkeypatch.setattr(session_tracker, "_file", tmp_path / "sessions.json")
    monkeypatch.setattr(session_tracker, "max_per_day", 5)
    session_tracker.reset_mode()
    session_tracker._sessions = []
    session_tracker._mark_dirty()
    session_tracker._save()
    yield
    session_tracker.reset_mode()
    session_tracker._sessions = []
    session_tracker._mark_dirty()
    session_tracker._save()


@pytest.fixture
def client():
    """TestClient с замоканными внешними вызовами."""
    mock_obsidian = MagicMock()
    mock_obsidian.ping = AsyncMock(return_value=False)
    mock_obsidian.available = False

    with (
        patch.object(orchestrator, "_check_network", AsyncMock(return_value=True)),
        patch.object(orchestrator, "_check_ollama", AsyncMock(return_value={
            "available": False, "version": None, "models": None, "model_ready": None,
        })),
        patch.object(orchestrator.state, "obsidian", mock_obsidian),
    ):
        orchestrator.logger.disabled = True
        with TestClient(app, client=("127.0.0.1", 50000)) as c:
            yield c


@pytest.fixture
def client_offline():
    """TestClient в offline-режиме."""
    mock_obsidian = MagicMock()
    mock_obsidian.ping = AsyncMock(return_value=False)
    mock_obsidian.available = False

    with (
        patch.object(orchestrator, "_check_network", AsyncMock(return_value=False)),
        patch.object(orchestrator, "_check_ollama", AsyncMock(return_value={
            "available": False, "version": None, "models": None, "model_ready": None,
        })),
        patch.object(orchestrator.state, "obsidian", mock_obsidian),
    ):
        orchestrator.logger.disabled = True
        with TestClient(app, client=("127.0.0.1", 50000)) as c:
            yield c


# ─── Тесты API Endpoints ───────────────────────────────


class TestAPIEndpoints:
    """Проверка базовых API эндпоинтов."""

    def test_root_returns_html(self, client):
        """Корень / отдаёт HTML-страницу."""
        resp = client.get("/")
        assert resp.status_code == 200
        assert "text/html" in resp.headers.get("content-type", "")
        assert "coli-dev" in resp.text

    def test_learning_progress_and_reviews_are_local_and_persistent(self, client):
        event_id = "f47ac10b-58cc-4372-a567-0e02b2c3d479"
        saved = client.post(
            "/learning/reviews",
            json={"event_id": event_id, "lesson_id": "intro.physics", "quality": 4},
        )
        assert saved.status_code == 200
        assert saved.json()["completed"] is True
        assert saved.json()["interval_days"] == 1

        progress = client.get("/learning/progress")
        assert progress.status_code == 200
        assert progress.json()["records"] == [saved.json()]
        assert progress.json()["due_count"] == 0

        replay = client.post(
            "/learning/reviews",
            json={"event_id": event_id, "lesson_id": "intro.physics", "quality": 4},
        )
        assert replay.status_code == 200
        assert replay.json() == saved.json()
        assert client.get("/learning/progress").json()["records"][0]["review_count"] == 1

    def test_learning_review_rejects_invalid_payload_and_cross_origin_requests(self, client):
        invalid = client.post(
            "/learning/reviews",
            json={
                "event_id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
                "lesson_id": "../../secrets",
                "quality": 4,
            },
        )
        assert invalid.status_code == 422

        wrong_origin = client.get(
            "/learning/progress", headers={"Origin": "https://attacker.example"}
        )
        assert wrong_origin.status_code == 403



    def test_api_status_returns_json(self, client):
        """/api/status возвращает JSON со статусом."""
        resp = client.get("/api/status")
        assert resp.status_code == 200
        data = resp.json()
        assert data["service"] == "coli-dev Orchestrator v4.0"
        assert data["version"] == "4.0.0"
        assert "online" in data
        assert "session" in data
        assert data["session"]["mode"] == "online"

    def test_health_returns_expected_structure(self, client):
        """/health возвращает все обязательные поля."""
        resp = client.get("/health")
        assert resp.status_code == 200
        data = resp.json()
        assert "status" in data
        assert "online" in data
        assert "provider" in data
        assert "gemini_model" in data
        assert "ollama_model" in data
        assert "ollama_embedding_model" in data
        assert "ollama_available" in data
        assert "uptime_sec" in data
        assert "session_mode" in data
        assert "session_current" in data
        assert "session_max" in data
        assert "knowledge_document_count" in data
        assert "knowledge_index_checked_at" in data

    def test_local_api_does_not_grant_cross_origin_browser_access(self, client):
        """A random website must not be able to call local vault write endpoints."""
        response = client.options(
            "/obsidian/write/lesson.md",
            headers={
                "Origin": "https://attacker.example",
                "Access-Control-Request-Method": "PUT",
                "Access-Control-Request-Headers": "content-type",
            },
        )

        assert "access-control-allow-origin" not in response.headers

    @pytest.mark.parametrize(("method", "path", "payload"), [
        ("GET", "/api/status", None),
        ("GET", "/health", None),
        ("GET", "/api/session", None),
        ("POST", "/api/session/reset", None),
        ("POST", "/chat/stream", {"message": "private lesson context"}),
        ("GET", "/obsidian/ping", None),
        ("GET", "/obsidian/list", None),
        ("GET", "/obsidian/read/private.md", None),
        ("PUT", "/obsidian/write/private.md", {"content": "private note"}),
        ("DELETE", "/obsidian/delete/private.md", None),
        ("POST", "/obsidian/search", {"query": "private topic"}),
    ])
    def test_local_api_rejects_untrusted_origins(self, client, method, path, payload):
        response = client.request(
            method,
            path,
            json=payload,
            headers={"Origin": "https://attacker.example"},
        )

        assert response.status_code == 403

    @pytest.mark.parametrize(("method", "path", "payload"), [
        ("GET", "/health", None),
        ("POST", "/chat/stream", {"message": "private lesson context"}),
        ("GET", "/obsidian/read/private.md", None),
        ("PUT", "/obsidian/write/private.md", {"content": "private note"}),
        ("DELETE", "/obsidian/delete/private.md", None),
    ])
    def test_sensitive_routes_reject_non_loopback_clients(self, method, path, payload):
        with TestClient(app, client=("203.0.113.42", 50000)) as remote_client:
            response = remote_client.request(method, path, json=payload)

        assert response.status_code == 403

    def test_provider_secret_status_does_not_return_values(self, client):
        response = client.get("/settings/api-keys")

        assert response.status_code == 200
        providers = {item["provider"]: item for item in response.json()["providers"]}
        assert providers["gemini"] == {
            "provider": "gemini", "configured": True, "source": "environment",
        }
        assert providers["obsidian"]["configured"] is False
        assert "test-gemini-key" not in response.text

    def test_keychain_value_takes_precedence_over_environment(self, monkeypatch):
        _, passwords = _mock_keyring(monkeypatch)
        passwords[("ColiDev", "KIMI_API_KEY")] = "keychain-kimi-secret"

        orchestrator._load_provider_secrets()

        assert orchestrator.KIMI_KEY == "keychain-kimi-secret"
        assert orchestrator._PROVIDER_SOURCES["kimi"] == "keychain"
        assert orchestrator.GEMINI_KEY == "test-gemini-key"
        assert orchestrator._PROVIDER_SOURCES["gemini"] == "environment"

    def test_provider_secret_endpoints_reject_non_loopback_clients(self):
        request = Request({
            "type": "http",
            "method": "GET",
            "path": "/settings/api-keys",
            "headers": [],
            "client": ("203.0.113.10", 50000),
        })

        with pytest.raises(HTTPException) as error:
            orchestrator._require_local_settings_request(request)

        assert error.value.status_code == 403

    def test_provider_secret_is_saved_to_keychain_without_echoing_it(self, client, monkeypatch):
        fake, passwords = _mock_keyring(monkeypatch)
        secret = "keyring-test-secret-483"

        response = client.put("/settings/api-keys/gemini", json={"api_key": f" {secret} "})

        assert response.status_code == 200
        assert response.json() == {"provider": "gemini", "configured": True, "source": "keychain"}
        assert passwords[("ColiDev", "GEMINI_API_KEY")] == secret
        assert orchestrator.GEMINI_KEY == secret
        assert secret not in response.text
        fake.set_password.assert_called_once_with("ColiDev", "GEMINI_API_KEY", secret)

    def test_invalid_secret_requests_never_echo_submitted_values(self, client):
        oversized = "private-input-" * 350
        response = client.put("/settings/api-keys/gemini", json={"api_key": oversized})
        assert response.status_code == 413
        assert oversized not in response.text

        wrong_type_secret = "private-wrong-type-input"
        response = client.put("/settings/api-keys/gemini", json={"api_key": [wrong_type_secret]})
        assert response.status_code == 400
        assert wrong_type_secret not in response.text

    def test_deleting_keychain_secret_restores_environment_fallback(self, client, monkeypatch):
        fake, passwords = _mock_keyring(monkeypatch)
        passwords[("ColiDev", "GEMINI_API_KEY")] = "stored-keychain-secret"
        orchestrator.GEMINI_KEY = "stored-keychain-secret"
        orchestrator._PROVIDER_SOURCES["gemini"] = "keychain"

        response = client.delete("/settings/api-keys/gemini")

        assert response.status_code == 200
        assert response.json() == {"provider": "gemini", "configured": True, "source": "environment"}
        assert orchestrator.GEMINI_KEY == "test-gemini-key"
        assert ("ColiDev", "GEMINI_API_KEY") not in passwords
        fake.delete_password.assert_called_once_with("ColiDev", "GEMINI_API_KEY")

    def test_provider_secret_rejects_foreign_browser_origin(self, client):
        response = client.put(
            "/settings/api-keys/gemini",
            json={"api_key": "not-stored"},
            headers={"Origin": "https://attacker.example"},
        )

        assert response.status_code == 403
        assert orchestrator.GEMINI_KEY == "test-gemini-key"

    def test_health_reports_whether_ollama_is_on_loopback(self, client, monkeypatch):
        monkeypatch.setattr(orchestrator, "OLLAMA_BASE", "http://192.168.1.20:11434")
        monkeypatch.setattr(orchestrator, "OBSIDIAN_URL", "https://vault.example/api")

        response = client.get("/health")

        assert response.status_code == 200
        assert response.json()["ollama_endpoint_local"] is False
        assert response.json()["obsidian_endpoint_local"] is False
        assert response.json()["gemini_key_configured"] is True

    def test_remote_obsidian_key_save_is_rejected(self, client, monkeypatch):
        monkeypatch.setattr(orchestrator, "OBSIDIAN_URL", "https://vault.example/api")
        secret = "obsidian-key-must-not-be-saved-or-echoed"

        response = client.put("/settings/api-keys/obsidian", json={"api_key": secret})

        assert response.status_code == 422
        assert secret not in response.text

    def test_api_session_returns_status(self, client):
        """/api/session возвращает статус сессий."""
        resp = client.get("/api/session")
        assert resp.status_code == 200
        data = resp.json()
        assert data["mode"] == "online"
        assert data["current"] == 0
        assert data["max"] == 5
        assert data["can_start"] is True

    def test_api_session_reset(self, client):
        """/api/session/reset сбрасывает режим."""
        session_tracker._mode = "local"
        resp = client.post("/api/session/reset")
        assert resp.status_code == 200
        data = resp.json()
        assert data["status"] == "ok"
        assert data["mode"] == "online"


class TestObsidianEndpoints:
    """Проверка Obsidian-эндпоинтов (503 если недоступен)."""

    def test_obsidian_ping_503_when_unavailable(self, client):
        """Obsidian ping возвращает 503 если не настроен."""
        resp = client.get("/obsidian/ping")
        assert resp.status_code == 503

    def test_obsidian_list_503_when_unavailable(self, client):
        """Obsidian list возвращает 503 если не настроен."""
        resp = client.get("/obsidian/list")
        assert resp.status_code == 503

    def test_obsidian_read_503_when_unavailable(self, client):
        """Obsidian read возвращает 503 если не настроен."""
        resp = client.get("/obsidian/read/test.md")
        assert resp.status_code == 503

    def test_obsidian_write_503_when_unavailable(self, client):
        """Obsidian write возвращает 503 если не настроен."""
        resp = client.put("/obsidian/write/test.md", json={"content": "test"})
        assert resp.status_code == 503

    def test_obsidian_delete_503_when_unavailable(self, client):
        """Obsidian delete возвращает 503 если не настроен."""
        resp = client.delete("/obsidian/delete/test.md")
        assert resp.status_code == 503

    def test_obsidian_search_503_when_unavailable(self, client):
        """Obsidian search возвращает 503 если не настроен."""
        resp = client.post("/obsidian/search", json={"query": "test"})
        assert resp.status_code == 503

    def test_invalid_vault_path_returns_422_without_calling_obsidian(self, client, monkeypatch):
        worker = MagicMock()
        worker.configured = True
        worker.close = AsyncMock()
        worker.list_files = AsyncMock(side_effect=ValueError("invalid path"))
        monkeypatch.setattr(orchestrator.state, "obsidian", worker)

        response = client.get("/obsidian/list", params={"path": "../outside.md"})

        assert response.status_code == 422
        assert response.json()["error"] == "Invalid Obsidian vault path"
        worker.list_files.assert_awaited_once_with("../outside.md")


# ─── Тесты SessionTracker ─────────────────────────────


class TestSessionTracker:
    """Проверка трекера сессий."""

    def test_can_start_session_initially(self):
        """Изначально можно начать сессию."""
        tracker = SessionTracker(max_per_day=5, duration_hours=1)
        tracker.reset_mode()
        tracker._sessions = []
        assert tracker.can_start_session() is True
        assert tracker.mode == "online"

    def test_session_limit_switches_to_local(self):
        """При исчерпании лимита переключается на local."""
        tracker = SessionTracker(max_per_day=2, duration_hours=1)
        tracker.reset_mode()
        tracker._sessions = []
        tracker.start_session()
        tracker.start_session()
        status = tracker.start_session()
        assert status["mode"] == "local"
        assert status["remaining"] == 0

    def test_local_mode_blocks_sessions(self):
        """В local-режиме новые сессии не начинаются."""
        tracker = SessionTracker(max_per_day=5, duration_hours=1)
        tracker._mode = "local"
        tracker._sessions = []
        assert tracker.can_start_session() is False

    def test_get_status_returns_correct_fields(self):
        """get_status возвращает все нужные поля."""
        tracker = SessionTracker(max_per_day=3, duration_hours=1)
        tracker.reset_mode()
        tracker._sessions = []
        status = tracker.get_status()
        assert "mode" in status
        assert "current" in status
        assert "max" in status
        assert "remaining" in status
        assert "can_start" in status
        assert status["max"] == 3


# ─── Тесты DebateLog ───────────────────────────────────


class TestDebateLog:
    """Проверка лога дебатов."""

    def test_empty_log_html(self):
        """Пустой лог генерирует пустой HTML."""
        log = DebateLog()
        html = log.to_html()
        assert "пуст" in html

    def test_log_add_and_html(self):
        """Добавление записи и генерация HTML."""
        log = DebateLog()
        log.add("cloud-code", "gemini-flash", "Test content", 100)
        log.add("consilium", "freebuff", "Review content", 200)
        html = log.to_html()
        assert "Gemini Flash (черновик)" in html
        assert "freebuff" in html or "Freebuff" in html
        assert "300" in html  # total duration

    def test_log_agent_icons(self):
        """Проверка иконок агентов."""
        log = DebateLog()
        assert log._agent_icon("gemini-flash") == "⚡"
        assert log._agent_icon("judge") == "⚖️"
        assert log._agent_icon("kimi") == "👑"
        assert log._agent_icon("freebuff") == "🦊"
        assert log._agent_icon("qwen") == "🐉"
        assert log._agent_icon("unknown") == "🤖"

    def test_log_agent_colors(self):
        """Проверка цветов агентов."""
        log = DebateLog()
        assert log._agent_color("gemini-flash") == "#7c5bf0"
        assert log._agent_color("freebuff") == "#f78166"
        assert log._agent_color("qwen") == "#3fb950"


# ─── Тесты SSE Streaming ───────────────────────────────


def _parse_sse(text: str) -> list[dict]:
    """Парсит SSE-ответ в список событий."""
    events = []
    for block in text.split("\n\n"):
        block = block.strip()
        if not block or not block.startswith("data: "):
            continue
        for line in block.split("\n"):
            line = line.strip()
            if line.startswith("data: "):
                try:
                    events.append(json.loads(line[6:]))
                except json.JSONDecodeError:
                    pass
    return events


class TestStreamingChat:
    """Проверка SSE-стриминга через /chat/stream."""

    def test_retrieval_sources_are_interleaved_and_citations_renumbered(self):
        courses = [
            {"id": "", "title": "Course A", "path": "02_Areas/a.md", "source_type": "course"},
            {"id": "", "title": "Course B", "path": "02_Areas/b.md", "source_type": "course"},
        ]
        notes = [
            {"id": "", "title": "note-a.md", "path": "note-a.md", "source_type": "obsidian"},
            {"id": "", "title": "note-b.md", "path": "note-b.md", "source_type": "obsidian"},
        ]

        sources = orchestrator._combine_retrieval_sources(courses, notes)

        assert [source["id"] for source in sources] == ["K1", "K2", "K3", "K4"]
        assert [source["source_type"] for source in sources] == ["course", "obsidian", "course", "obsidian"]

    def test_retrieval_prompt_marks_filesystem_dates_as_unverified_metadata(self):
        prompt = orchestrator._augment_prompt_with_sources(
            "Tutor prompt",
            [{
                "id": "K1",
                "title": "Functions",
                "path": "02_Areas/math.md",
                "location": "3-7",
                "modified_at": "2026-10-04T10:00:00Z",
                "source_checked_at": "2026-10-05",
                "excerpt": "An example excerpt.",
            }],
            "en",
        )

        assert "[K1]" in prompt
        assert "02_Areas/math.md" in prompt
        assert "Lines: 3-7" in prompt
        assert "File modified at: 2026-10-04T10:00:00Z" in prompt
        assert "Source references checked (note metadata): 2026-10-05" in prompt
        assert "not independent verification" in prompt
        assert "not proof of publication" in prompt

    def test_stream_returns_sse(self, client):
        """/chat/stream возвращает SSE-ответ."""
        mock_answer = "print('Hello, world!')"
        mock_log = DebateLog()
        mock_log.add("consilium", "consensus", "Final answer", 500)

        mock_engine = MagicMock()
        mock_engine.run = AsyncMock(return_value=(mock_answer, mock_log))

        with patch("orchestrator.ConsiliumEngine", return_value=mock_engine):
            resp = client.post("/chat/stream", json={"message": TEST_MSG})
            assert resp.status_code == 200
            assert "text/event-stream" in resp.headers.get("content-type", "")

    def test_stream_contains_debate_log_and_tokens(self, client):
        """Стрим содержит лог дебатов и токены ответа."""
        mock_answer = "Hello world code"
        mock_log = DebateLog()
        mock_log.add("cloud-code", "gemini-flash", "Draft", 100)
        mock_log.add("consilium", "consensus", "Final", 200)

        mock_engine = MagicMock()
        mock_engine.run = AsyncMock(return_value=(mock_answer, mock_log))

        course_source = {
            "title": "Hello World",
            "excerpt": "A first Python program.",
            "retrieved_at": "2026-10-05T12:00:00Z",
            "modified_at": "2026-10-04T12:00:00Z",
            "path": "02_Areas/python/hello.md",
            "location": "2-5",
            "source_type": "course",
        }
        with (
            patch("orchestrator.ConsiliumEngine", return_value=mock_engine),
            patch("orchestrator._retrieve_local_course_sources", AsyncMock(return_value=[course_source])),
            patch("orchestrator._retrieve_obsidian_sources", AsyncMock(return_value=[])),
        ):
            resp = client.post("/chat/stream", json={"message": TEST_MSG})
            events = _parse_sse(resp.text)

            types = [e["type"] for e in events]
            assert "debate_log" in types
            assert "token" in types
            assert "done" in types

            tokens = [e["content"] for e in events if e["type"] == "token"]
            full_text = "".join(tokens)
            assert "Hello" in full_text
            assert "world" in full_text

    def test_stream_done_event_has_metadata(self, client):
        """Событие done содержит метаданные (provider, model, duration_ms)."""
        mock_answer = "test"
        mock_log = DebateLog()

        mock_engine = MagicMock()
        mock_engine.run = AsyncMock(return_value=(mock_answer, mock_log))

        course_source = {
            "title": "Hello World",
            "excerpt": "A first Python program.",
            "retrieved_at": "2026-10-05T12:00:00Z",
            "modified_at": "2026-10-04T12:00:00Z",
            "path": "02_Areas/python/hello.md",
            "location": "2-5",
            "source_type": "course",
        }
        with (
            patch("orchestrator.ConsiliumEngine", return_value=mock_engine),
            patch("orchestrator._retrieve_local_course_sources", AsyncMock(return_value=[course_source])),
            patch("orchestrator._retrieve_obsidian_sources", AsyncMock(return_value=[])),
        ):
            resp = client.post("/chat/stream", json={"message": TEST_MSG})
            events = _parse_sse(resp.text)
            done_events = [e for e in events if e["type"] == "done"]
            assert len(done_events) == 1
            done = done_events[0]
            assert done["provider"] == "consilium"
            assert done["model"] == "multi-agent"
            assert "duration_ms" in done
            assert "tokens" in done
            assert done["sources"][0]["id"] == "K1"
            assert done["sources"][0]["path"] == "02_Areas/python/hello.md"
            assert done["sources"][0]["modified_at"] == "2026-10-04T12:00:00Z"

    def test_grounded_web_search_is_direct_and_skips_local_retrieval(self, client):
        source = {
            "id": "1",
            "title": "Official source",
            "excerpt": "",
            "retrieved_at": "2026-10-05T12:00:00Z",
            "path": "https://vertexaisearch.cloud.google.com/redirect?q=1",
            "source_type": "google_grounding",
        }
        instances = []
        class StubEngine(orchestrator.ConsiliumEngine):
            def __init__(self, *args, **kwargs):
                super().__init__(*args, **kwargs)
                instances.append(self)
                self.web_sources = [source]
                self.search_entry_point_html = "<a>Google Search</a>"
                self.run_grounded = AsyncMock(return_value="Current answer. [1](<https://example.org>)")

        with (
            patch("orchestrator.ConsiliumEngine", StubEngine),
            patch("orchestrator._retrieve_local_course_sources", AsyncMock()) as local_search,
            patch("orchestrator._retrieve_obsidian_sources", AsyncMock()) as obsidian_search,
        ):
            response = client.post("/chat/stream", json={
                "message": "What changed this year?",
                "system_prompt": "Lesson context",
                "use_web_search": True,
                "grounding_age_confirmed": True,
            })

        assert response.status_code == 200
        events = _parse_sse(response.text)
        done = next(event for event in events if event["type"] == "done")
        assert done["provider"] == "gemini-grounded"
        assert done["sources"] == [source]
        assert done["google_search_suggestions"] == "<a>Google Search</a>"
        assert "debate_log" not in [event["type"] for event in events]
        instances[0].run_grounded.assert_awaited_once_with(
            "What changed this year?", "Lesson context"
        )
        local_search.assert_not_awaited()
        obsidian_search.assert_not_awaited()

    @pytest.mark.parametrize(("mode", "online"), [("local", True), ("auto", False)])
    def test_grounded_web_search_requires_auto_and_network(self, client, monkeypatch, mode, online):
        monkeypatch.setattr(orchestrator, "_check_network", AsyncMock(return_value=online))
        with patch("orchestrator.ConsiliumEngine") as engine_factory:
            response = client.post("/chat/stream", json={
                "message": "Find current information",
                "mode": mode,
                "use_web_search": True,
                "grounding_age_confirmed": True,
            })

        assert response.status_code == 200
        events = _parse_sse(response.text)
        assert any(event["type"] == "error" for event in events)
        engine_factory.assert_not_called()

    def test_grounded_web_search_requires_age_confirmation(self, client):
        with patch("orchestrator.ConsiliumEngine") as engine_factory:
            response = client.post("/chat/stream", json={
                "message": "Find current information",
                "use_web_search": True,
            })

        assert response.status_code == 200
        events = _parse_sse(response.text)
        error = next(event for event in events if event["type"] == "error")
        assert "18" in error["error"]
        engine_factory.assert_not_called()

    def test_grounded_web_search_requires_gemini_key(self, client, monkeypatch):
        monkeypatch.setattr(orchestrator, "GEMINI_KEY", "")
        with patch("orchestrator.ConsiliumEngine") as engine_factory:
            response = client.post("/chat/stream", json={
                "message": "Find current information",
                "language": "en",
                "use_web_search": True,
                "grounding_age_confirmed": True,
            })

        events = _parse_sse(response.text)
        error = next(event for event in events if event["type"] == "error")
        assert "Gemini API key" in error["error"]
        engine_factory.assert_not_called()

    def test_grounded_web_search_respects_daily_session_limit(self, client, monkeypatch):
        monkeypatch.setattr(orchestrator.session_tracker, "can_start_session", lambda: False)
        network_check = AsyncMock()
        monkeypatch.setattr(orchestrator, "_check_network", network_check)
        with patch("orchestrator.ConsiliumEngine") as engine_factory:
            response = client.post("/chat/stream", json={
                "message": "Find current information",
                "language": "en",
                "use_web_search": True,
                "grounding_age_confirmed": True,
            })

        events = _parse_sse(response.text)
        error = next(event for event in events if event["type"] == "error")
        assert "online session limit" in error["error"]
        network_check.assert_not_awaited()
        engine_factory.assert_not_called()

    def test_stream_local_mode(self, client_offline):
        """В offline-режиме стрим идёт через Digital Twin (Qwen)."""
        mock_answer = "Локальный ответ"
        mock_log = DebateLog()
        mock_log.add("consilium", "qwen", "Local response", 100)

        mock_engine = MagicMock()
        mock_engine.run_local = AsyncMock(return_value=(mock_answer, mock_log))

        with patch("orchestrator.ConsiliumEngine", return_value=mock_engine):
            resp = client_offline.post("/chat/stream", json={"message": TEST_MSG})
            assert resp.status_code == 200
            events = _parse_sse(resp.text)
            done_events = [e for e in events if e["type"] == "done"]
            assert len(done_events) == 1
            assert done_events[0]["provider"] == "local"


# ─── Тесты ConsiliumEngine ─────────────────────────────


class TestConsiliumEngine:
    """Проверка движка консилиума (без async/await — используем asyncio.run)."""

    @pytest.mark.parametrize(("url", "expected"), [
        ("http://127.0.0.1:11434", True),
        ("http://localhost:11434", True),
        ("http://localhost.:11434", True),
        ("https://[::1]:11434", True),
        ("http://192.168.1.20:11434", False),
        ("http://0.0.0.0:11434", False),
        ("http://localhost..:11434", False),
        ("http://user:pass@localhost:11434", False),
        ("https://example.com/ollama", False),
        ("http://localhost:not-a-port", False),
        ("http://localhost:11434/api?target=remote", False),
    ])
    def test_loopback_service_url_policy(self, url, expected):
        assert orchestrator._is_loopback_http_url(url) is expected

    def test_ollama_request_is_blocked_before_network_for_remote_url(self, monkeypatch):
        mock_client = MagicMock(spec=httpx.AsyncClient)
        mock_client.post = AsyncMock()
        monkeypatch.setattr(orchestrator, "OLLAMA_BASE", "http://192.168.1.20:11434")
        engine = orchestrator.ConsiliumEngine(mock_client)

        response = asyncio.run(engine._ask_ollama(TEST_MSG, SYSTEM_PROMPT, "privacy-check"))

        assert "Ollama endpoint must use localhost" in response
        mock_client.post.assert_not_awaited()

    def test_remote_obsidian_search_is_skipped(self, monkeypatch):
        mock_obsidian = MagicMock()
        mock_obsidian.configured = True
        mock_obsidian.base_url = "https://vault.example"
        mock_obsidian.search = AsyncMock(return_value=[{"path": "private.md", "content": "secret"}])
        monkeypatch.setattr(orchestrator.state, "obsidian", mock_obsidian)

        sources = asyncio.run(orchestrator._retrieve_obsidian_sources("private query"))

        assert sources == []
        mock_obsidian.search.assert_not_awaited()

    def test_google_grounding_keeps_only_public_http_sources_and_cites_them(self):
        candidate = {
            "groundingMetadata": {
                "searchEntryPoint": {"renderedContent": "<a>Google Search</a>"},
                "groundingChunks": [
                    {"web": {
                        "uri": "https://vertexaisearch.cloud.google.com/redirect?x=1&y=2",
                        "title": "Example source",
                    }},
                    {"web": {"uri": "file:///private/key", "title": "local file"}},
                    {"web": {"uri": "https://127.0.0.1/private", "title": "local service"}},
                ],
                "groundingSupports": [
                    {"segment": {"endIndex": 13}, "groundingChunkIndices": [0, 1, 2]},
                ],
            },
        }

        sources, suggestions = orchestrator._grounding_sources(candidate)
        cited = orchestrator._add_grounding_citations("Current fact.", candidate)

        assert [source["id"] for source in sources] == ["1"]
        assert sources[0]["source_type"] == "google_grounding"
        assert suggestions == "<a>Google Search</a>"
        assert cited == "Current fact. [1](<https://vertexaisearch.cloud.google.com/redirect?x=1&y=2>)"

    @pytest.mark.parametrize(("url", "expected"), [
        ("https://example.org/source", True),
        ("https://xn--e1afmkfd.xn--p1ai/source", True),
        ("https://localhost/source", False),
        ("http://127.0.0.1/source", False),
        ("https://[::1]/source", False),
        ("https://example.org:bad/source", False),
        ("https://bad domain.example/source", False),
        ("https://bad..example/source", False),
    ])
    def test_google_grounding_url_policy(self, url, expected):
        assert orchestrator._safe_grounding_url(url) is expected

    def test_grounded_gemini_request_requires_sources_and_search_suggestions(self, monkeypatch):
        monkeypatch.setattr(orchestrator, "GEMINI_KEY", "test-gemini-key")
        response = MagicMock()
        response.raise_for_status = MagicMock()
        response.json.return_value = {
            "candidates": [{
                "content": {"parts": [{"text": "The current fact is supported."}]},
                "groundingMetadata": {
                    "searchEntryPoint": {"renderedContent": "<a>Google Search</a>"},
                    "groundingChunks": [{"web": {
                        "uri": "https://vertexaisearch.cloud.google.com/redirect?q=1",
                        "title": "Official source",
                    }}],
                    "groundingSupports": [{
                        "segment": {"endIndex": 30},
                        "groundingChunkIndices": [0],
                    }],
                },
            }],
        }
        client = MagicMock(spec=httpx.AsyncClient)
        client.post = AsyncMock(return_value=response)
        engine = orchestrator.ConsiliumEngine(client)

        answer = asyncio.run(engine.run_grounded("What is current?", "Tutor context"))

        request = client.post.await_args.kwargs
        assert request["json"]["tools"] == [{"google_search": {}}]
        assert answer.startswith("The current fact is supported. [1](<https://")
        assert engine.web_sources[0]["title"] == "Official source"
        assert engine.search_entry_point_html == "<a>Google Search</a>"

    def test_grounded_gemini_rejects_unattributed_answer(self, monkeypatch):
        monkeypatch.setattr(orchestrator, "GEMINI_KEY", "test-gemini-key")
        response = MagicMock()
        response.raise_for_status = MagicMock()
        response.json.return_value = {
            "candidates": [{"content": {"parts": [{"text": "An ungrounded answer."}]}}],
        }
        client = MagicMock(spec=httpx.AsyncClient)
        client.post = AsyncMock(return_value=response)
        engine = orchestrator.ConsiliumEngine(client)

        answer = asyncio.run(engine.run_grounded("Question", "Tutor context"))

        assert answer.startswith("[Google Search:")
        assert engine.web_sources == []
        assert engine.search_entry_point_html is None

    def test_malformed_grounding_metadata_is_ignored_safely(self):
        assert orchestrator._grounding_sources({"groundingMetadata": []}) == ([], None)
        assert orchestrator._grounding_sources({"groundingMetadata": {"groundingChunks": [None]}}) == ([], None)
        assert orchestrator._add_grounding_citations("unchanged", {"groundingMetadata": "bad"}) == "unchanged"

    def test_lifespan_never_connects_to_remote_obsidian(self, monkeypatch):
        monkeypatch.setattr(orchestrator, "OBSIDIAN_URL", "https://vault.example/api")
        monkeypatch.setattr(orchestrator, "OBSIDIAN_API_KEY", "must-not-leave-this-device")
        monkeypatch.setattr(orchestrator, "_load_provider_secrets", MagicMock())
        monkeypatch.setattr(orchestrator, "_check_network", AsyncMock(return_value=True))
        worker = MagicMock()
        monkeypatch.setattr(orchestrator, "ObsidianWorker", worker)

        async def exercise_lifespan():
            async with orchestrator.lifespan(orchestrator.app):
                assert orchestrator.state.obsidian is None

        asyncio.run(exercise_lifespan())

        worker.assert_not_called()

    def test_engine_run_returns_tuple(self):
        """run возвращает (answer, log) кортеж."""
        mock_client = MagicMock(spec=httpx.AsyncClient)

        # Provider responses match their actual API formats.
        mock_gemini_response = MagicMock()
        mock_gemini_response.status_code = 200
        mock_gemini_response.json.return_value = {
            "candidates": [{"content": {"parts": [{"text": FAKE_ANSWER}]}}]
        }
        mock_gemini_response.raise_for_status = MagicMock()
        mock_gemini_response.text = ""

        mock_kimi_response = MagicMock()
        mock_kimi_response.status_code = 200
        mock_kimi_response.json.return_value = {
            "choices": [{"message": {"content": FAKE_ANSWER}}]
        }
        mock_kimi_response.raise_for_status = MagicMock()
        mock_kimi_response.text = ""

        # Ollama-формат для Qwen Researcher
        mock_ollama_response = MagicMock()
        mock_ollama_response.status_code = 200
        mock_ollama_response.json.return_value = {
            "message": {"content": "Ключевые моменты из исследования"}
        }
        mock_ollama_response.raise_for_status = MagicMock()
        mock_ollama_response.text = ""

        def side_effect(url, **kwargs):
            url = str(url)
            if "localhost:11434" in url or "127.0.0.1:11434" in url:
                return mock_ollama_response
            if "api.moonshot.cn" in url:
                return mock_kimi_response
            if "generativelanguage.googleapis.com" in url:
                return mock_gemini_response
            raise AssertionError(f"Unexpected provider request in test: {url}")

        mock_client.post = AsyncMock(side_effect=side_effect)

        engine = orchestrator.ConsiliumEngine(mock_client)
        answer, log = asyncio.run(engine.run(TEST_MSG, SYSTEM_PROMPT))

        assert isinstance(answer, str)
        assert isinstance(log, DebateLog)
        assert answer == FAKE_ANSWER
        agents = {entry["agent"] for entry in log._entries}
        assert {"gemini-flash", "judge", "kimi", "ollama-gen", "freebuff", "qwen", "consensus"} <= agents

    def test_engine_run_local_returns_tuple(self):
        """run_local возвращает (answer, log) кортеж."""
        mock_client = MagicMock(spec=httpx.AsyncClient)

        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "message": {"content": "Локальный ответ"}
        }
        mock_response.raise_for_status = MagicMock()
        mock_response.text = ""
        mock_client.post = AsyncMock(return_value=mock_response)

        engine = orchestrator.ConsiliumEngine(mock_client)
        answer, log = asyncio.run(engine.run_local(TEST_MSG, SYSTEM_PROMPT))

        assert isinstance(answer, str)
        assert isinstance(log, DebateLog)
        assert "[Ошибка" not in answer


# ─── Тест замера памяти ────────────────────────────────


class TestMemoryFootprint:
    """Замер потребления RAM."""

    RSS_THRESHOLD_MB = 20

    def _rss_mb(self) -> float:
        gc.collect()
        return PROC.memory_info().rss / 1024 / 1024

    def test_memory_does_not_leak(self, client):
        """Память не должна существенно расти после 10 запросов."""
        rss_before = self._rss_mb()

        mock_answer = "test response"
        mock_log = DebateLog()
        mock_log.add("consilium", "consensus", "answer", 100)

        mock_engine = MagicMock()
        mock_engine.run = AsyncMock(return_value=(mock_answer, mock_log))
        mock_engine.run_local = AsyncMock(return_value=(mock_answer, mock_log))

        with patch("orchestrator.ConsiliumEngine", return_value=mock_engine):
            for i in range(10):
                resp = client.post(
                    "/chat/stream",
                    json={"message": f"Запрос номер {i}"},
                )
                assert resp.status_code == 200

        rss_after = self._rss_mb()
        growth = rss_after - rss_before

        print(
            f"\n📊 Memory: {rss_before:.1f} MB → {rss_after:.1f} MB  "
            f"(growth: {growth:+.1f} MB, limit: {self.RSS_THRESHOLD_MB} MB)"
        )
        assert growth < self.RSS_THRESHOLD_MB, (
            f"Возможная утечка памяти: {growth:+.1f} MB за 10 запросов "
            f"(лимит: {self.RSS_THRESHOLD_MB} MB)"
        )


# ─── Запуск напрямую ──────────────────────────────────


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
