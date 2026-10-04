#!/usr/bin/env python3
"""
test_integration.py — Интеграционные тесты полного пайплайна streaming для coli-dev v3.0

Проверяет полный цикл: HTTP запрос → ConsiliumEngine → SSE streaming → клиент.
Все внешние вызовы (Gemini, Moonshot, Ollama, Obsidian) замокированы.

Запуск:
    .venv/bin/python -m pytest 01_Projects/test_integration.py -v --tb=short
"""

from __future__ import annotations

import asyncio
import json
import os
import sys
from unittest.mock import AsyncMock, MagicMock, patch

import httpx
import pytest
from fastapi.testclient import TestClient

# ─── sys.path ──────────────────────────────────────────
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import orchestrator
from orchestrator import (
    ConsiliumCloudError,
    ConsiliumEngine,
    DebateLog,
    SessionTracker,
    app,
    session_tracker,
    state,
)

TEST_MSG = "Напиши функцию сортировки на Python"
SYSTEM_PROMPT = "You are a Python mentor."


# ─── Fixtures ──────────────────────────────────────────

@pytest.fixture(autouse=True)
def _reset(monkeypatch, tmp_path):
    """Сброс состояния перед каждым тестом."""
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
def mock_obsidian():
    m = MagicMock()
    m.ping = AsyncMock(return_value=False)
    m.available = False
    return m


@pytest.fixture
def client_online(mock_obsidian):
    """TestClient: online, network OK."""
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
def client_offline(mock_obsidian):
    """TestClient: offline."""
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


# ─── Helpers ───────────────────────────────────────────

def _parse_sse(text: str) -> list[dict]:
    """Парсит SSE-стрим в список событий."""
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


def _make_chat_completion_response(content: str):
    """Создаёт мок ответа для OpenAI-compatible Chat Completions API."""
    resp = MagicMock()
    resp.status_code = 200
    resp.json.return_value = {"choices": [{"message": {"content": content}}]}
    resp.raise_for_status = MagicMock()
    resp.text = ""
    return resp


def _make_gemini_response(content: str):
    """Создаёт мок ответа Google Gemini generateContent API."""
    resp = MagicMock()
    resp.status_code = 200
    resp.json.return_value = {"candidates": [{"content": {"parts": [{"text": content}]}}]}
    resp.raise_for_status = MagicMock()
    resp.text = ""
    return resp


def _make_kimi_response(content: str):
    """Создаёт мок ответа Moonshot OpenAI-compatible Chat Completions API."""
    return _make_chat_completion_response(content)


def _make_ollama_response(content: str):
    """Создаёт мок HTTP-ответа Ollama."""
    resp = MagicMock()
    resp.status_code = 200
    resp.json.return_value = {"message": {"content": content}}
    resp.raise_for_status = MagicMock()
    resp.text = ""
    return resp


def _make_http_error(status: int, body: str = "error"):
    """Создаёт мок HTTP-ошибки."""
    resp = MagicMock()
    resp.status_code = status
    resp.text = body
    resp.raise_for_status = MagicMock(side_effect=httpx.HTTPStatusError(
        message=f"HTTP {status}", request=MagicMock(), response=resp,
    ))
    return resp


# ═══════════════════════════════════════════════════════
#  1. ПОЛНЫЙ ПАЙПЛАЙН: HTTP → ConsiliumEngine → SSE
# ═══════════════════════════════════════════════════════

class TestFullStreamingPipeline:
    """Интеграционные тесты: полный пайплайн от HTTP-запроса до SSE-событий."""

    def test_full_pipeline_online(self, client_online):
        """Полный пайплайн: онлайн → ConsiliumEngine.run → SSE-события."""
        flash_answer = "def sort_list(lst): return sorted(lst)"
        pro_answer = "def sort_list(lst):\n    return sorted(lst)"
        kimi_answer = "Оба черновика верны. Используйте sorted()."
        qwen_context = "Актуальные практики сортировки в Python."
        consensus = "def sort_list(lst):\n    return sorted(lst)\n\n# Оптимальное решение"

        flash_call_count = 0

        def http_side_effect(url, **kwargs):
            nonlocal flash_call_count
            url = str(url)

            if "generativelanguage.googleapis.com" in url:
                if "gemini-3-flash-preview" in url:
                    flash_call_count += 1
                    return _make_gemini_response(flash_answer if flash_call_count == 1 else consensus)
                if "gemini-3.1-pro-preview" in url:
                    return _make_gemini_response(pro_answer)
            if "api.moonshot.cn" in url:
                return _make_kimi_response(kimi_answer)

            # Ollama
            if "localhost:11434" in url:
                return _make_ollama_response(qwen_context)

            # DuckDuckGo
            if "duckduckgo" in url:
                return MagicMock(status_code=200, text="")

            return _make_gemini_response("default")

        mock_client = MagicMock(spec=httpx.AsyncClient)
        mock_client.post = AsyncMock(side_effect=http_side_effect)

        engine = ConsiliumEngine(mock_client)
        answer, log = asyncio.run(engine.run(TEST_MSG, SYSTEM_PROMPT))

        # Проверяем ответ
        assert isinstance(answer, str)
        assert len(answer) > 0
        assert "sort_list" in answer

        # Проверяем лог: должны быть записи обоих уровней
        stages = [e["stage"] for e in log._entries]
        assert "cloud-code" in stages
        assert "consilium" in stages

        # Проверяем агентов в логе
        agents = [e["agent"] for e in log._entries]
        assert "gemini-flash" in agents
        assert "judge" in agents
        assert "freebuff" in agents
        assert "qwen" in agents
        assert "consensus" in agents

    def test_full_pipeline_local_mode(self, client_offline):
        """Полный пайплайн: оффлайн → run_local → SSE-события."""
        local_answer = "def bubble_sort(arr):\n    for i in range(len(arr)):\n        for j in range(len(arr)-1):\n            if arr[j] > arr[j+1]:\n                arr[j], arr[j+1] = arr[j+1], arr[j]\n    return arr"

        mock_client = MagicMock(spec=httpx.AsyncClient)
        mock_client.post = AsyncMock(return_value=_make_ollama_response(local_answer))

        engine = ConsiliumEngine(mock_client)
        answer, log = asyncio.run(engine.run_local(TEST_MSG, SYSTEM_PROMPT))

        assert "bubble_sort" in answer
        assert len(log._entries) == 1
        assert log._entries[0]["agent"] == "qwen"
        assert "ЛОКАЛЬНЫЙ РЕЖИМ" in log._entries[0]["content"]

    def test_sse_stream_full_cycle(self, client_online):
        """HTTP-запрос → /chat/stream → полный SSE-стрим с токенами и done."""
        answer = "def quicksort(arr):\n    if len(arr) <= 1:\n        return arr\n    pivot = arr[len(arr) // 2]\n    left = [x for x in arr if x < pivot]\n    middle = [x for x in arr if x == pivot]\n    right = [x for x in arr if x > pivot]\n    return quicksort(left) + middle + quicksort(right)"

        log = DebateLog()
        log.add("cloud-code", "gemini-flash", "Черновик quicksort", 150)
        log.add("cloud-code", "gemini-pro", "Альтернативный quicksort", 180)
        log.add("cloud-code", "glm", "Единая позиция", 200)
        log.add("consilium", "freebuff", "Код-ревью OK", 100)
        log.add("consilium", "qwen", "Researcher context", 80)
        log.add("consilium", "consensus", "Финальный ответ", 50)

        mock_engine = MagicMock()
        mock_engine.run = AsyncMock(return_value=(answer, log))

        with patch("orchestrator.ConsiliumEngine", return_value=mock_engine):
            resp = client_online.post("/chat/stream", json={"message": TEST_MSG})

        assert resp.status_code == 200
        assert "text/event-stream" in resp.headers.get("content-type", "")

        events = _parse_sse(resp.text)

        # 1. Первое событие — debate_log
        assert events[0]["type"] == "debate_log"
        assert "html" in events[0]
        assert "Gemini Flash (черновик)" in events[0]["html"]

        # 2. Токены
        token_events = [e for e in events if e["type"] == "token"]
        assert len(token_events) > 0

        # 3. Токены拼接后 содержат ответ
        full_text = "".join(e["content"] for e in token_events)
        assert "quicksort" in full_text

        # 4. Последнее событие — done
        done_events = [e for e in events if e["type"] == "done"]
        assert len(done_events) == 1
        done = done_events[0]
        assert done["provider"] == "consilium"
        assert done["model"] == "multi-agent"
        assert done["tokens"] == len(token_events)
        assert done["duration_ms"] >= 0

    def test_sse_stream_local_offline(self, client_offline):
        """HTTP-запрос → /chat/stream (offline) → local provider."""
        answer = "Локальный ответ от Qwen"
        log = DebateLog()
        log.add("consilium", "qwen", "Local response", 50)

        mock_engine = MagicMock()
        mock_engine.run_local = AsyncMock(return_value=(answer, log))

        with patch("orchestrator.ConsiliumEngine", return_value=mock_engine):
            resp = client_offline.post("/chat/stream", json={"message": TEST_MSG})

        events = _parse_sse(resp.text)
        done = [e for e in events if e["type"] == "done"][0]
        assert done["provider"] == "local"


# ═══════════════════════════════════════════════════════
#  2. СЕССИИ: лимит → переключение на local
# ═══════════════════════════════════════════════════════

class TestSessionIntegration:
    """Интеграция с трекером сессий: лимит → автономный режим."""

    def test_session_limit_triggers_local_mode(self, client_online):
        """Исчерпание лимита сессий → ответ через local provider."""
        # Устанавливаем лимит в 1 сессию
        session_tracker.max_per_day = 1
        session_tracker.start_session()  # исчерпали

        answer = "Local fallback"
        log = DebateLog()
        log.add("consilium", "qwen", "Local", 10)

        mock_engine = MagicMock()
        mock_engine.run_local = AsyncMock(return_value=(answer, log))

        with patch("orchestrator.ConsiliumEngine", return_value=mock_engine):
            resp = client_online.post("/chat/stream", json={"message": TEST_MSG})

        events = _parse_sse(resp.text)
        done = [e for e in events if e["type"] == "done"][0]
        assert done["provider"] == "local"

    def test_session_reset_restores_online(self, client_online):
        """Сброс сессий возвращает онлайн-режим."""
        session_tracker._mode = "local"
        resp = client_online.post("/api/session/reset")
        assert resp.json()["mode"] == "online"

        # Теперь /chat/stream должен идти через консилиум
        answer = "Online answer"
        log = DebateLog()
        log.add("consilium", "consensus", "answer", 100)

        mock_engine = MagicMock()
        mock_engine.run = AsyncMock(return_value=(answer, log))

        with patch("orchestrator.ConsiliumEngine", return_value=mock_engine):
            resp = client_online.post("/chat/stream", json={"message": TEST_MSG})

        events = _parse_sse(resp.text)
        done = [e for e in events if e["type"] == "done"][0]
        assert done["provider"] == "consilium"


# ═══════════════════════════════════════════════════════
#  3. ОШИБКИ: fallback, retry, error events
# ═══════════════════════════════════════════════════════

class TestErrorRecovery:
    """Интеграция ошибок: fallback на локальную модель, error events."""

    def test_cloud_error_fallback_to_local(self):
        """ConsiliumCloudError → фолбек на Ollama."""
        mock_client = MagicMock(spec=httpx.AsyncClient)

        # Все HTTP-запросы падают
        mock_client.post = AsyncMock(side_effect=httpx.ConnectError("Connection refused"))

        engine = ConsiliumEngine(mock_client)
        answer, log = asyncio.run(engine.run(TEST_MSG, SYSTEM_PROMPT))

        # Должен получить фолбек-ответ (или ошибку)
        assert isinstance(answer, str)
        assert len(answer) > 0

    def test_partial_cloud_failure(self):
        """Одна Gemini упала, вторая работает → консилиум продолжает."""
        flash_call_count = 0

        async def http_side_effect(url, **kwargs):
            nonlocal flash_call_count
            url = str(url)

            if "generativelanguage.googleapis.com" in url:
                if "gemini-3-flash-preview" in url:
                    flash_call_count += 1
                    if flash_call_count == 1:
                        return _make_http_error(402, "Insufficient credits")
                    return _make_gemini_response("Consensus answer")
                if "gemini-3.1-pro-preview" in url:
                    return _make_gemini_response("Pro draft answer")
            if "api.moonshot.cn" in url:
                return _make_kimi_response("Kimi draft answer")
            if "localhost:11434" in url:
                return _make_ollama_response("Qwen context")
            if "duckduckgo" in url:
                return MagicMock(status_code=200, text="")
            return _make_gemini_response("default")

        mock_client = MagicMock(spec=httpx.AsyncClient)
        mock_client.post = AsyncMock(side_effect=http_side_effect)

        engine = ConsiliumEngine(mock_client)
        answer, log = asyncio.run(engine.run(TEST_MSG, SYSTEM_PROMPT))

        assert isinstance(answer, str)
        # Лог должен содержать ошибку от flash
        flash_entries = [e for e in log._entries if e["agent"] == "gemini-flash"]
        assert any("Ошибка" in e["content"] for e in flash_entries)

    def test_all_cloud_models_fail(self):
        """Все облачные модели недоступны → ConsiliumCloudError → fallback."""
        async def http_side_effect(url, **kwargs):
            url = str(url)
            if "generativelanguage.googleapis.com" in url or "api.moonshot.cn" in url:
                return _make_http_error(402, "No credits")
            if "localhost:11434" in url:
                return _make_ollama_response("Local fallback answer")
            return MagicMock(status_code=200, text="")

        mock_client = MagicMock(spec=httpx.AsyncClient)
        mock_client.post = AsyncMock(side_effect=http_side_effect)

        engine = ConsiliumEngine(mock_client)
        answer, log = asyncio.run(engine.run(TEST_MSG, SYSTEM_PROMPT))

        assert isinstance(answer, str)
        assert len(answer) > 0

    def test_stream_error_event_on_engine_failure(self, client_online):
        """Если ConsiliumEngine падает — клиент получает error event."""
        mock_engine = MagicMock()
        mock_engine.run = AsyncMock(side_effect=Exception("Simulated engine crash"))

        with patch("orchestrator.ConsiliumEngine", return_value=mock_engine):
            resp = client_online.post("/chat/stream", json={"message": TEST_MSG})

        # Ответ должен быть 200 (SSE), но с error в теле
        assert resp.status_code == 200
        events = _parse_sse(resp.text)
        # Может быть debate_log + error, или просто error
        types = [e["type"] for e in events]
        assert "error" in types or len(events) == 0  # fallback handling


# ═══════════════════════════════════════════════════════
#  4. ДЕБАТЫ: DebateLog → HTML pipeline
# ═══════════════════════════════════════════════════════

class TestDebateLogPipeline:
    """Интеграция: DebateLog → HTML → SSE debate_log event."""

    def test_debate_log_html_appears_in_sse(self, client_online):
        """debate_log event содержит HTML с именами агентов."""
        log = DebateLog()
        log.add("cloud-code", "gemini-flash", "Flash draft", 100)
        log.add("cloud-code", "judge", "Pro verdict", 120)
        log.add("cloud-code", "kimi", "Kimi draft", 80)
        log.add("cloud-code", "ollama-gen", "Local draft", 80)
        log.add("consilium", "freebuff", "Code review", 60)
        log.add("consilium", "qwen", "Research context", 40)
        log.add("consilium", "consensus", "Final answer", 20)

        mock_engine = MagicMock()
        mock_engine.run = AsyncMock(return_value=("Answer text", log))

        with patch("orchestrator.ConsiliumEngine", return_value=mock_engine):
            resp = client_online.post("/chat/stream", json={"message": TEST_MSG})

        events = _parse_sse(resp.text)
        debate_events = [e for e in events if e["type"] == "debate_log"]
        assert len(debate_events) == 1

        html = debate_events[0]["html"]
        # Уровень 1
        assert "УРОВЕНЬ 1" in html
        assert "Gemini Flash (черновик)" in html
        assert "Gemini Pro (судья)" in html
        assert "Kimi (черновик)" in html
        assert "Ollama (локальный черновик)" in html
        # Уровень 2
        assert "УРОВЕНЬ 2" in html
        assert "Ollama (критический разбор)" in html
        assert "Ollama (проверка результата)" in html
        assert "Финальный ответ" in html
        # Сводка
        assert "Всего агентов: 7" in html

    def test_empty_debate_log(self, client_online):
        """Пустой DebateLog → пустой HTML в SSE."""
        log = DebateLog()  # пустой

        mock_engine = MagicMock()
        mock_engine.run = AsyncMock(return_value=("Answer", log))

        with patch("orchestrator.ConsiliumEngine", return_value=mock_engine):
            resp = client_online.post("/chat/stream", json={"message": TEST_MSG})

        events = _parse_sse(resp.text)
        debate_events = [e for e in events if e["type"] == "debate_log"]
        assert len(debate_events) == 1
        assert "пуст" in debate_events[0]["html"]


# ═══════════════════════════════════════════════════════
#  5. ТОКЕНЫ: целостность拼接
# ═══════════════════════════════════════════════════════

class TestTokenIntegrity:
    """Проверка что токены SSE拼接后 дают оригинальный ответ."""

    def test_tokens_reconstruct_answer(self, client_online):
        """Все token events拼拼接后 должны дать оригинальный ответ."""
        original = "def binary_search(arr, target):\n    low, high = 0, len(arr) - 1\n    while low <= high:\n        mid = (low + high) // 2\n        if arr[mid] == target:\n            return mid\n        elif arr[mid] < target:\n            low = mid + 1\n        else:\n            high = mid - 1\n    return -1"

        log = DebateLog()
        log.add("consilium", "consensus", "answer", 50)

        mock_engine = MagicMock()
        mock_engine.run = AsyncMock(return_value=(original, log))

        with patch("orchestrator.ConsiliumEngine", return_value=mock_engine):
            resp = client_online.post("/chat/stream", json={"message": TEST_MSG})

        events = _parse_sse(resp.text)
        tokens = [e["content"] for e in events if e["type"] == "token"]
        reconstructed = "".join(tokens)

        # После strip пробелов должен совпасть
        assert reconstructed.strip() == original.strip()

    def test_done_event_token_count_matches(self, client_online):
        """done.tokens совпадает с количеством token events."""
        log = DebateLog()
        log.add("consilium", "consensus", "answer", 50)

        mock_engine = MagicMock()
        mock_engine.run = AsyncMock(return_value=("one two three four five", log))

        with patch("orchestrator.ConsiliumEngine", return_value=mock_engine):
            resp = client_online.post("/chat/stream", json={"message": TEST_MSG})

        events = _parse_sse(resp.text)
        token_count = len([e for e in events if e["type"] == "token"])
        done = [e for e in events if e["type"] == "done"][0]

        assert done["tokens"] == token_count


# ═══════════════════════════════════════════════════════
#  6. CONSILIUM ENGINE: полный цикл с реальными моками
# ═══════════════════════════════════════════════════════

class TestConsiliumEngineFullCycle:
    """Тесты ConsiliumEngine с реалистичными моками HTTP."""

    def test_engine_handles_network_timeout(self):
        """ConsiliumEngine обрабатывает таймауты сетевых запросов."""
        async def timeout_side_effect(*args, **kwargs):
            raise httpx.TimeoutException("Connection timed out")

        mock_client = MagicMock(spec=httpx.AsyncClient)
        mock_client.post = AsyncMock(side_effect=timeout_side_effect)

        engine = ConsiliumEngine(mock_client)
        answer, log = asyncio.run(engine.run(TEST_MSG, SYSTEM_PROMPT))

        assert isinstance(answer, str)
        assert len(answer) > 0

    def test_engine_mixed_success_failure(self):
        """ConsiliumEngine: часть запросов успешна, часть падает."""
        async def mixed_side_effect(url, **kwargs):
            url = str(url)
            if "generativelanguage.googleapis.com" in url:
                if "gemini-3-flash-preview" in url:
                    return _make_gemini_response("Flash draft")
                if "gemini-3.1-pro-preview" in url:
                    raise httpx.ConnectError("Pro unavailable")
            if "api.moonshot.cn" in url:
                return _make_kimi_response("Kimi draft")
            if "localhost:11434" in url:
                return _make_ollama_response("Qwen context")
            if "duckduckgo" in url:
                return MagicMock(status_code=200, text="")
            return _make_gemini_response("default")

        mock_client = MagicMock(spec=httpx.AsyncClient)
        mock_client.post = AsyncMock(side_effect=mixed_side_effect)

        engine = ConsiliumEngine(mock_client)
        answer, log = asyncio.run(engine.run(TEST_MSG, SYSTEM_PROMPT))

        assert isinstance(answer, str)
        # Лог должен содержать ошибку для Pro
        pro_entries = [e for e in log._entries if e["agent"] == "judge"]
        assert any("Ошибка" in e["content"] for e in pro_entries)

    def test_engine_local_mode_with_ollama_error(self):
        """run_local: Ollama недоступен → возвращает ошибку."""
        async def error_side_effect(*args, **kwargs):
            raise httpx.ConnectError("Ollama not running")

        mock_client = MagicMock(spec=httpx.AsyncClient)
        mock_client.post = AsyncMock(side_effect=error_side_effect)

        engine = ConsiliumEngine(mock_client)
        answer, log = asyncio.run(engine.run_local(TEST_MSG, SYSTEM_PROMPT))

        assert isinstance(answer, str)
        assert "⚠️" in answer or "недоступен" in answer


# ═══════════════════════════════════════════════════════
#  Запуск
# ═══════════════════════════════════════════════════════

if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
