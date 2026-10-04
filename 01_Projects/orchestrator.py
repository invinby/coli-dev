#!/usr/bin/env .venv/bin/python
"""
coli-dev Orchestrator  v4.0 — Коворкинг
────────────────────────────────────────────────────────
Архитектура дебатов v4.0:

  УРОВЕНЬ 1: Генераторы + Верховный Судья
    ├─ Gemini 3 Flash Preview  → черновик архитектуры
    ├─ Gemini 3.1 Pro Preview  → черновик архитектуры
    ├─ Ollama (Qwen 2.5)       → черновик архитектуры
    └─ 👑 Kimi K3 (судья)      → единый эталонный консенсус

  УРОВЕНЬ 2: Локальный Критик
    ├─ Freebuff (Mimo 2.5)   → код-ревью, оптимизация
    ├─ Qwen 2.5 Coder 7B     → мгновенная верификация синтаксиса
    └─ Финальный ответ       → скоординированный ответ

  ВЫХОД: Obsidian Vault (HTTP, Bearer auth)

Запуск:
    .venv/bin/python 01_Projects/orchestrator.py

Документация:
    http://127.0.0.1:8000/docs

Idle потребление: ~35-50 MB RSS, 0% CPU на Mac M1 16GB
"""

from __future__ import annotations

import asyncio
import json
import logging
import os
import re
import uuid
from contextlib import asynccontextmanager
from contextvars import ContextVar
from datetime import datetime, timezone, timedelta
from pathlib import Path
from typing import Any, Literal

import httpx
from dotenv import load_dotenv

from obsidian_worker import ObsidianWorker
from fastapi import FastAPI, HTTPException, Request, Response
from fastapi.responses import HTMLResponse, JSONResponse, StreamingResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from slowapi import Limiter
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address

# ─── Bootstrap: .env ───────────────────────────────────
_env_path = Path(__file__).resolve().parent.parent / ".env"
load_dotenv(_env_path)

# ─── Config ────────────────────────────────────────────

# Moonshot AI → Kimi K3 (Верховный Судья)
KIMI_KEY = os.getenv("KIMI_API_KEY", "")
KIMI_URL = "https://api.moonshot.cn/v1/chat/completions"
KIMI_MODEL = os.getenv("KIMI_MODEL", "moonshot-v1-auto")  # Kimi K3

# Google → Gemini (напрямую)
GEMINI_KEY = os.getenv("GEMINI_API_KEY", "")
GEMINI_FLASH_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent"
GEMINI_PRO_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-pro-preview:generateContent"

# Ollama (локально)
OLLAMA_BASE = os.getenv("OLLAMA_URL", "http://localhost:11434")
OLLAMA_CHAT_URL = f"{OLLAMA_BASE}/api/chat"
OLLAMA_MODEL_RESEARCHER = os.getenv("OLLAMA_RESEARCHER", "qwen2.5-coder:7b")

# Таймауты
HTTP_TIMEOUT = float(os.getenv("HTTP_TIMEOUT", "90"))
NET_CHECK_TIMEOUT = float(os.getenv("NET_CHECK_TIMEOUT", "4"))

# Obsidian
OBSIDIAN_URL = os.getenv("OBSIDIAN_URL", "http://127.0.0.1:27123")
OBSIDIAN_API_KEY = os.getenv("OBSIDIAN_API_KEY", "")

# Сервер
HOST = os.getenv("HOST", "127.0.0.1")
PORT = int(os.getenv("PORT", "8000"))
DEV_MODE = os.getenv("DEV_MODE", "false").lower() in ("true", "1", "yes")

# Rate limiting
CHAT_RATE_LIMIT = os.getenv("CHAT_RATE_LIMIT", "30/minute")

# Сессии
SESSION_MAX_PER_DAY = int(os.getenv("SESSION_MAX_PER_DAY", "999"))
SESSION_DURATION_HOURS = int(os.getenv("SESSION_DURATION_HOURS", "1"))
SESSION_FILE = Path.home() / "Library" / "Application Support" / "coli-dev" / "sessions.json"

# DuckDuckGo search
DDG_URL = "https://html.duckduckgo.com/html/"

# ─── Structured Logging ────────────────────────────────

_request_id: ContextVar[str] = ContextVar("request_id", default="-")
_log_dir = Path.home() / "Library" / "Logs" / "coli-dev"


class JSONFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        entry: dict[str, object] = {
            "ts": datetime.fromtimestamp(record.created, tz=timezone.utc).isoformat(),
            "level": record.levelname,
            "logger": record.name,
            "msg": record.getMessage(),
            "request_id": _request_id.get(),
            "pid": record.process,
        }
        extras = {
            k: v for k, v in record.__dict__.items()
            if k not in (
                "args", "asctime", "created", "exc_info", "exc_text", "filename",
                "funcName", "levelname", "levelno", "lineno", "message",
                "module", "msecs", "msg", "name", "pathname", "process",
                "processName", "relativeCreated", "stack_info", "thread",
                "threadName", "request_id",
            )
        }
        if extras:
            entry["data"] = extras
        if record.exc_info and record.exc_info[0]:
            entry["exc"] = self.formatException(record.exc_info)
        return json.dumps(entry, default=str, ensure_ascii=False)


class HumanFormatter(logging.Formatter):
    LEVEL_COLORS = {
        "DEBUG": "\033[36m", "INFO": "\033[32m", "WARNING": "\033[33m",
        "ERROR": "\033[31m", "CRITICAL": "\033[41m",
    }
    RESET = "\033[0m"

    def format(self, record: logging.LogRecord) -> str:
        ts = self.formatTime(record, "%H:%M:%S")
        color = self.LEVEL_COLORS.get(record.levelname, "")
        rid = _request_id.get()[:12]
        extras = {}
        for k, v in record.__dict__.items():
            if k not in (
                "args", "asctime", "created", "exc_info", "exc_text", "filename",
                "funcName", "levelname", "levelno", "lineno", "message",
                "module", "msecs", "msg", "name", "pathname", "process",
                "processName", "relativeCreated", "stack_info", "thread",
                "threadName", "request_id",
            ):
                extras[k] = v
        extra_str = f" {extras}" if extras else ""
        return (
            f"{ts} {color}{record.levelname:<7}{self.RESET} "
            f"[{rid}] {record.name}: {record.getMessage()}{extra_str}"
        )


_log_level = logging.DEBUG if DEV_MODE else logging.INFO
_log_file = _log_dir / "orchestrator.jsonl"
_log_dir.mkdir(parents=True, exist_ok=True)

fh = logging.FileHandler(_log_file, encoding="utf-8")
fh.setLevel(_log_level)
fh.setFormatter(JSONFormatter())

sh = logging.StreamHandler()
sh.setLevel(_log_level)
sh.setFormatter(HumanFormatter())

logging.basicConfig(level=_log_level, handlers=[fh, sh])
logger = logging.getLogger("colidev")
logger.info(
    "Logging initialized",
    extra={"log_file": str(_log_file), "dev_mode": DEV_MODE, "level": logging.getLevelName(_log_level)},
)

# ─── Pydantic schemas ─────────────────────────────────


class ChatRequest(BaseModel):
    message: str
    system_prompt: str = "You are a concise Python mentor. Answer briefly, with code examples."
    model: str | None = None
    language: Literal["ru", "en"] = "ru"
    mode: Literal["auto", "local"] = "auto"


class HealthResponse(BaseModel):
    status: str
    online: bool
    provider: str
    gemini_model: str
    ollama_model: str
    ollama_available: bool
    ollama_version: str | None = None
    ollama_models: list[str] | None = None
    ollama_model_ready: bool | None = None
    uptime_sec: int
    session_mode: str
    session_current: int
    session_max: int


class ErrorResponse(BaseModel):
    error: str
    provider: str | None = None
    online: bool | None = None


# ─── Session Tracker ──────────────────────────────────


class SessionTracker:
    """Трекер сессий Freebuff: 1 час на сессию, до 5 раз в день.

    При исчерпании лимитов автоматически переключает режим на
    'Автономный локальный' (Digital Twin на базе Qwen 3).
    """

    def __init__(self, max_per_day: int = 5, duration_hours: int = 1) -> None:
        self.max_per_day = max_per_day
        self.duration_hours = duration_hours
        self._file = SESSION_FILE
        self._file.parent.mkdir(parents=True, exist_ok=True)
        self._sessions: list[dict[str, Any]] = []
        self._mode: str = "online"  # "online" | "local"
        self._load()

    def _load(self) -> None:
        """Загрузить сессии из JSON-файла."""
        if self._file.exists():
            try:
                data = json.loads(self._file.read_text(encoding="utf-8"))
                self._sessions = data.get("sessions", [])
                self._mode = data.get("mode", "online")
            except (json.JSONDecodeError, KeyError):
                self._sessions = []
                self._mode = "online"
        self._prune_expired()

    _dirty: bool = False

    def _save(self) -> None:
        """Сохранить сессии в JSON-файл (только если были изменения)."""
        if not self._dirty:
            return
        self._file.write_text(
            json.dumps({"sessions": self._sessions, "mode": self._mode}, ensure_ascii=False, default=str),
            encoding="utf-8"
        )
        self._dirty = False

    def _mark_dirty(self) -> None:
        self._dirty = True

    def _prune_expired(self) -> None:
        """Удалить истекшие сессии и сессии не за сегодня."""
        today = datetime.now(timezone.utc).date()
        old_len = len(self._sessions)
        self._sessions = [
            s for s in self._sessions
            if s.get("date") == str(today)
        ]
        if len(self._sessions) != old_len:
            self._mark_dirty()

    def can_start_session(self) -> bool:
        """Можно ли начать новую сессию?"""
        self._prune_expired()
        if self._mode == "local":
            return False
        today_sessions = len(self._sessions)
        return today_sessions < self.max_per_day

    def start_session(self) -> dict[str, Any]:
        """Начать новую сессию. Возвращает статус."""
        self._prune_expired()
        now = datetime.now(timezone.utc)

        if self._mode == "local":
            return self.get_status()

        if len(self._sessions) >= self.max_per_day:
            # Лимит исчерпан — переключаем в локальный режим
            self._mode = "online"
            self._mark_dirty()
            self._save()
            logger.info("Session limit reached → switching to LOCAL autonomous mode")
            return self.get_status()

        session = {
            "id": uuid.uuid4().hex[:12],
            "date": str(now.date()),
            "start": now.isoformat(),
            "expires": (now + timedelta(hours=self.duration_hours)).isoformat(),
        }
        self._sessions.append(session)
        self._mark_dirty()
        self._save()
        logger.info("Session started", extra={"session_id": session["id"], "count": len(self._sessions)})
        return self.get_status()

    def get_status(self) -> dict[str, Any]:
        """Получить статус сессий."""
        self._prune_expired()
        today_count = len(self._sessions)
        return {
            "mode": self._mode,
            "current": today_count,
            "max": self.max_per_day,
            "remaining": self.max_per_day - today_count if self._mode == "online" else 0,
            "can_start": self.can_start_session(),
        }

    @property
    def mode(self) -> str:
        return self._mode

    @property
    def current(self) -> int:
        self._prune_expired()
        return len(self._sessions)

    def reset_mode(self) -> None:
        """Принудительно вернуть онлайн-режим (для тестов)."""
        self._mode = "online"
        self._mark_dirty()
        self._save()

    @property
    def is_local_mode(self) -> bool:
        """True если в автономном локальном режиме (Digital Twin)."""
        return self._mode == "local"


session_tracker = SessionTracker(
    max_per_day=SESSION_MAX_PER_DAY,
    duration_hours=SESSION_DURATION_HOURS,
)


# ─── Consilium Engine ─────────────────────────────────


class DebateLog:
    """Коллектор логов дебатов для формирования HTML-отчёта."""

    def __init__(self) -> None:
        self._entries: list[dict[str, str]] = []

    def add(self, stage: str, agent: str, content: str, duration_ms: int = 0) -> None:
        self._entries.append({
            "stage": stage,
            "agent": agent,
            "content": content,
            "duration_ms": duration_ms,
        })

    def to_html(self) -> str:
        """Сгенерировать HTML-содержимое для тега <details>."""
        if not self._entries:
            return "<p>Лог дебатов пуст.</p>"

        lines = []
        for entry in self._entries:
            agent_icon = self._agent_icon(entry["agent"])
            agent_color = self._agent_color(entry["agent"])
            duration = f" ({entry['duration_ms']}ms)" if entry["duration_ms"] else ""
            lines.append(
                f'<div style="margin-bottom:6px;padding:6px 10px;background:#1a1a2e;border-radius:6px;'
                f'border-left:3px solid {agent_color};">'
                f'<div style="font-size:11px;color:#8b949e;margin-bottom:2px;">'
                f'{agent_icon} <strong style="color:{agent_color};">{self._agent_label(entry["agent"])}</strong>'
                f' — {entry["stage"]}{duration}</div>'
                f'<div style="font-size:12px;color:#e6edf3;white-space:pre-wrap;word-break:break-word;">'
                f'{self._escape(entry["content"][:600])}</div>'
                f'</div>'
            )

        stages = set(e["stage"] for e in self._entries)
        stage_labels = {
            "cloud-code": "🏛️ УРОВЕНЬ 1 — Облачное ядро Cloud Code",
            "consilium": "🤝 УРОВЕНЬ 2 — Общий Консилиум Коворкинга",
        }
        stage_colors = {
            "cloud-code": "var(--gemini, #7c5bf0)",
            "consilium": "var(--freebuff, #f78166)",
        }

        html = ""
        for stage in ["cloud-code", "consilium"]:
            stage_entries = [e for e in self._entries if e["stage"] == stage]
            if stage_entries:
                label = stage_labels.get(stage, stage)
                color = stage_colors.get(stage, "#58a6ff")
                html += (
                    f'<div style="margin-top:10px;margin-bottom:6px;font-size:11px;font-weight:700;'
                    f'color:{color};text-transform:uppercase;letter-spacing:0.5px;">'
                    f'{label}</div>'
                )
                for entry in stage_entries:
                    agent_icon = self._agent_icon(entry["agent"])
                    agent_color = self._agent_color(entry["agent"])
                    duration = f" ({entry['duration_ms']}ms)" if entry["duration_ms"] else ""
                    html += (
                        f'<div style="margin-bottom:6px;padding:6px 10px;background:#1a1a2e;border-radius:6px;'
                        f'border-left:3px solid {agent_color};">'
                        f'<div style="font-size:11px;color:#8b949e;margin-bottom:2px;">'
                        f'{agent_icon} <strong style="color:{agent_color};">{self._agent_label(entry["agent"])}</strong>'
                        f' — {entry["stage"]}{duration}</div>'
                        f'<div style="font-size:12px;color:#e6edf3;white-space:pre-wrap;word-break:break-word;">'
                        f'{self._escape(entry["content"][:800])}</div>'
                        f'</div>'
                    )

        # Сводка
        total_ms = sum(e["duration_ms"] for e in self._entries)
        html += (
            f'<div style="margin-top:8px;padding:4px 10px;font-size:10px;color:#8b949e;text-align:right;">'
            f'Всего агентов: {len(self._entries)} · Общее время: {total_ms}ms</div>'
        )
        return html

    @staticmethod
    def _agent_icon(agent: str) -> str:
        icons = {
            "gemini-flash": "⚡", "gemini-pro": "◇", "glm": "🔮",
            "cloud-code": "☁️", "freebuff": "🦊", "qwen": "🐉",
            "consensus": "✅", "kimi": "👑",
        }
        return icons.get(agent, "🤖")

    @staticmethod
    def _agent_label(agent: str) -> str:
        labels = {
            "gemini-flash": "Gemini 3.5 Flash", "gemini-pro": "Gemini 3.1 Pro",
            "glm": "GLM 5.2 (Генератор)", "cloud-code": "Cloud Code Position",
            "freebuff": "Freebuff (Критик, Mimo 2.5)", "qwen": "Qwen 2.5 Coder 7B (Верификатор)",
            "consensus": "Финальный консенсус", "kimi": "Kimi K3 (Верховный Судья)",
        }
        return labels.get(agent, agent)

    @staticmethod
    def _agent_color(agent: str) -> str:
        colors = {
            "gemini-flash": "#7c5bf0", "gemini-pro": "#5b8af0",
            "glm": "#f0c05b", "cloud-code": "#58a6ff",
            "freebuff": "#f78166", "qwen": "#3fb950",
            "consensus": "#f0883e", "kimi": "#ff6b9d",
        }
        return colors.get(agent, "#8b949e")

    @staticmethod
    def _escape(text: str) -> str:
        return (
            text.replace("&", "&amp;")
            .replace("<", "&lt;").replace(">", "&gt;")
            .replace('"', "&quot;").replace("'", "&#39;")
        )


class ConsiliumCloudError(Exception):
    """Все облачные модели недоступны — пора переключиться на локальный режим."""
    pass


class ConsiliumEngine:
    """Двухуровневый консилиум для обработки запроса пользователя."""

    def __init__(self, http_client: httpx.AsyncClient, language: str = "ru") -> None:
        self.http = http_client
        self.language = language if language in {"ru", "en"} else "ru"
        self.log = DebateLog()

    @property
    def output_language(self) -> str:
        return "Russian" if self.language == "ru" else "English"

    @property
    def language_system(self) -> str:
        if self.language == "en":
            return (
                "You are a helpful, careful learning assistant. Answer only in English. "
                "Be accurate, clear, and explain concepts at the learner's level. "
                "Use Python code fences when code is needed."
            )
        return (
            "Ты — полезный и внимательный учебный ИИ-помощник. Отвечай только на русском языке. "
            "Будь точным, понятным и объясняй материал на уровне ученика. "
            "Если нужен код на Python — используй блоки кода."
        )

    def agent_system(self, task_prompt: str = "") -> str:
        return f"{self.language_system}\n\n{task_prompt}" if task_prompt else self.language_system

    async def run(self, message: str, system_prompt: str) -> tuple[str, DebateLog]:
        """Запустить полный цикл консилиума.

        Returns:
            (final_answer, debate_log)
        """
        self.log = DebateLog()
        final_answer = ""

        try:
            # ─── УРОВЕНЬ 1: Cloud Code ───────────────────
            cloud_position = await self._run_cloud_code(message, system_prompt)

            # ─── УРОВЕНЬ 2: Общий Консилиум ──────────────
            final_answer = await self._run_consilium(message, system_prompt, cloud_position)

        except Exception as exc:
            logger.error("Consilium failed", extra={"error": str(exc)[:200]}, exc_info=True)
            # Фолбек: пытаемся получить хоть какой-то ответ от локальной модели
            try:
                final_answer = await self._fallback_local(message, system_prompt)
                self.log.add("consilium", "qwen",
                             f"[ФОЛБЕК] Консилиум не завершился. Ответ от локальной модели:\n{final_answer[:300]}...")
            except Exception:
                final_answer = (
                    "⚠️ Консилиум не смог обработать запрос. Попробуйте ещё раз или переключитесь на локальный режим."
                    if self.language == "ru" else
                    "⚠️ The tutor could not process this request. Try again or switch to the local route."
                )

        return final_answer, self.log

    # ─── УРОВЕНЬ 1: Генераторы + Верховный Судья (Kimi K3) ──

    async def _run_cloud_code(self, message: str, system_prompt: str) -> str:
        """Параллельный опрос 3 генераторов + судейство Gemini Pro.

        Returns:
            Единая облачная позиция (cloud position).
        """
        logger.info("Level 1: Cloud Code — requesting Gemini Flash + Kimi K3 + Ollama")

        # 1. Параллельные запросы к трём генераторам
        t0 = datetime.now(timezone.utc)
        agent_system = self.agent_system(system_prompt)
        gemini_flash_task = self._ask_gemini(message, agent_system,
                                             GEMINI_FLASH_URL, "gemini-flash")
        kimi_task = self._ask_kimi(message, agent_system, "kimi")
        ollama_task = self._ask_ollama(message, agent_system, "ollama-gen")

        flash_result, kimi_result, ollama_result = await asyncio.gather(
            gemini_flash_task, kimi_task, ollama_task, return_exceptions=True
        )

        flash_draft = flash_result if isinstance(flash_result, str) else f"[Ошибка: {flash_result}]"
        kimi_draft = kimi_result if isinstance(kimi_result, str) else f"[Ошибка: {kimi_result}]"
        ollama_draft = ollama_result if isinstance(ollama_result, str) else f"[Ошибка: {ollama_result}]"

        # Если все три вернули ошибки
        if all("Ошибка" in d for d in [flash_draft, kimi_draft, ollama_draft]):
            logger.warning("All generators unavailable → ConsiliumCloudError")
            raise ConsiliumCloudError(
                "Все генераторы недоступны. Проверьте GEMINI_API_KEY, KIMI_API_KEY и Ollama"
            )

        # 2. Gemini 2.5 Pro — Судья: анализирует все три черновика
        judge_prompt = (
            "Ты — 👑 Верховный Судья, главный архитектор-координатор. "
            "Проанализируй три черновика архитектуры от разных моделей. "
            "Выбери лучшее решение или синтезируй единую, эталонную позицию. "
            "Учти: правильность, производительность, читаемость кода, "
            "совместимость с Python 3.11+, FastAPI, асинхронность.\n\n"
            f"Черновик Gemini 2.0 Flash:\n{flash_draft}\n\n"
            f"Черновик Kimi K3:\n{kimi_draft}\n\n"
            f"Черновик Ollama (Qwen 2.5 Coder):\n{ollama_draft}\n\n"
            f"Final verdict in {self.output_language}:"
        )

        t1 = datetime.now(timezone.utc)
        cloud_position = await self._ask_gemini(judge_prompt, self.agent_system(system_prompt),
                                                GEMINI_PRO_URL, "judge")
        judge_duration = int((datetime.now(timezone.utc) - t1).total_seconds() * 1000)

        self.log.add("cloud-code", "gemini-flash",
                     flash_draft[:400], int((t1 - t0).total_seconds() * 1000))
        self.log.add("cloud-code", "kimi",
                     kimi_draft[:400], int((t1 - t0).total_seconds() * 1000))
        self.log.add("cloud-code", "ollama-gen",
                     ollama_draft[:400], int((t1 - t0).total_seconds() * 1000))
        self.log.add("cloud-code", "judge",
                     cloud_position[:400], judge_duration)

        logger.info("Cloud Code complete", extra={
            "flash_len": len(flash_draft), "kimi_len": len(kimi_draft),
            "ollama_len": len(ollama_draft), "judge_len": len(cloud_position),
        })

        return cloud_position

    # ─── УРОВЕНЬ 2: Локальный Критик ────────────────────

    async def _run_consilium(self, message: str, system_prompt: str,
                              cloud_position: str) -> str:
        """Freebuff (Ollama) + Qwen 2.5 Coder → валидация + финальный ответ."""
        logger.info("Level 2: Local Critic — Freebuff + Qwen 2.5 Coder verifying")

        # 1. Freebuff (Ollama): строгий код-ревью
        t0 = datetime.now(timezone.utc)
        freebuff_prompt = (
            "Ты — Freebuff, Главный Архитектор и строгий код-ревьюер. "
            "Проверь облачную позицию Cloud Code на:\n"
            "1) Соответствие PEP 8 и Python 3.11+\n"
            "2) Оптимизацию для Mac M1 (16GB, fanless) — избегай тяжёлых зависимостей\n"
            "3) Корректность асинхронного кода (FastAPI/httpx)\n"
            "4) Безопасность (нет SQL-инъекций, XSS, hardcoded secrets)\n"
            "5) Читаемость и документацию\n\n"
            f"Облачная позиция Cloud Code (от Kimi K3):\n{cloud_position}\n\n"
            f"Critical review in {self.output_language}:"
        )
        freebuff_review = await self._ask_ollama(freebuff_prompt, self.agent_system(system_prompt), "freebuff")
        fb_duration = int((datetime.now(timezone.utc) - t0).total_seconds() * 1000)

        # 2. Qwen 2.5 Coder 7B: мгновенная верификация синтаксиса (локально)
        t1 = datetime.now(timezone.utc)
        qwen_verify_prompt = (
            "Ты — Qwen 2.5 Coder 7B, локальный верификатор кода. "
            "Проверь синтаксис и логику кода из облачной позиции. "
            "Выдай краткий вердикт: ✅ корректно или ❌ ошибки (укажи какие).\n\n"
            f"Код:\n{cloud_position[:1500]}\n\n"
            f"Verdict in {self.output_language} (2-3 sentences):"
        )
        qwen_verify = await self._ask_ollama(qwen_verify_prompt, self.agent_system(system_prompt), "qwen")
        qw_duration = int((datetime.now(timezone.utc) - t1).total_seconds() * 1000)

        # 3. Финальный синтез
        t2 = datetime.now(timezone.utc)
        consensus_prompt = (
            "You are the coli-dev learning tutor coordinator. Consider the expert drafts and "
            "the learner's question below.\n\n"
            f"1. Main model's position:\n{cloud_position}\n\n"
            f"2. Critical review:\n{freebuff_review}\n\n"
            f"3. Local verification:\n{qwen_verify}\n\n"
            f"Learner's question: {message}\n\n"
            f"Synthesize one clear, coordinated answer in {self.output_language}. "
            "Be useful, accurate, and understandable. Use code fences when needed. "
            "Be concise without sacrificing quality."
        )
        final_answer = await self._ask_gemini(consensus_prompt, self.agent_system(system_prompt),
                                               GEMINI_FLASH_URL, "consensus")
        consensus_duration = int((datetime.now(timezone.utc) - t2).total_seconds() * 1000)

        self.log.add("consilium", "freebuff",
                     freebuff_review[:400], fb_duration)
        self.log.add("consilium", "qwen",
                     qwen_verify[:400], qw_duration)
        self.log.add("consilium", "consensus",
                     f"Финальный ответ ({len(final_answer)} символов)", consensus_duration)

        logger.info("Consilium complete", extra={
            "fb_len": len(freebuff_review), "qw_len": len(qwen_verify),
            "final_len": len(final_answer),
        })

        # 4. Автосохранение саммари в Obsidian Vault (фоновая задача)
        task = asyncio.create_task(self._save_to_obsidian(message, final_answer))
        task.add_done_callback(self._obsidian_task_done)

        return final_answer

    @staticmethod
    def _obsidian_task_done(task: asyncio.Task) -> None:
        """Callback для фоновой задачи Obsidian — логируем ошибки."""
        if task.exception():
            logger.warning("Obsidian: background save failed",
                           extra={"error": str(task.exception())[:100]})

    async def _save_to_obsidian(self, question: str, answer: str) -> None:
        """Автосохранение саммари диалога в Obsidian Vault."""
        if not state.obsidian_available:
            return
        try:
            now = datetime.now(timezone.utc)
            date_str = now.strftime("%Y-%m-%d")
            time_str = now.strftime("%H-%M")
            filename = f"coli-dev/sessions/{date_str}_{time_str}_consilium.md"

            summary = (
                f"# 🧠 Консилиум v4.0 — {date_str} {time_str}\n\n"
                f"**Вопрос:** {question[:200]}\n\n"
                f"**Ответ:** {answer[:1000]}\n\n"
                f"---\n"
                f"*Сгенерировано автоматически coli-dev v4.0*"
            )
            await state.obsidian.write(filename, summary)
            logger.info("Obsidian: summary saved", extra={"path": filename})
        except ConnectionError as exc:
            logger.debug("Obsidian: connection failed (offline)", extra={"error": str(exc)[:80]})
        except Exception as exc:
            logger.warning("Obsidian: failed to save summary", extra={"error": str(exc)[:100]})

    # ─── Локальный режим (Digital Twin) ─────────────────

    async def run_local(self, message: str, system_prompt: str) -> tuple[str, DebateLog]:
        """Автономный локальный режим на базе Qwen 2.5 (Digital Twin)."""
        self.log = DebateLog()
        t0 = datetime.now(timezone.utc)

        local_prompt = (
            "You are the local learning assistant powered by Ollama. "
            f"Answer in {self.output_language}; explain carefully with useful examples. "
            "Be accurate and concise.\n\n"
            f"Tutor guidance: {system_prompt}\n\n"
            f"Learner question: {message}"
        )

        try:
            response = await self._ask_ollama(local_prompt, self.language_system, "qwen")
            duration = int((datetime.now(timezone.utc) - t0).total_seconds() * 1000)
            self.log.add("consilium", "qwen",
                         f"[ЛОКАЛЬНЫЙ РЕЖИМ] Digital Twin ответил ({len(response)} символов)", duration)
            return response, self.log
        except Exception as exc:
            logger.error("Local mode failed", extra={"error": str(exc)[:200]})
            error = (
                "⚠️ Локальный режим недоступен. Проверьте Ollama."
                if self.language == "ru" else
                "⚠️ Local mode is unavailable. Check the configured Ollama model."
            )
            return error, self.log

    # ─── HTTP-запросы ↓ ─────────────────────────────────

    async def _ask_kimi(self, message: str, system_prompt: str, agent_tag: str) -> str:
        """Запрос к Kimi K3 через Moonshot AI (напрямую)."""
        if not KIMI_KEY:
            return f"[KIMI_API_KEY not set: {agent_tag}]"
        payload = {
            "model": KIMI_MODEL,
            "max_tokens": 2048,
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": message},
            ],
        }
        headers = {
            "Authorization": f"Bearer {KIMI_KEY}",
            "Content-Type": "application/json",
        }
        try:
            resp = await self.http.post(KIMI_URL, json=payload, headers=headers,
                                         timeout=HTTP_TIMEOUT)
            resp.raise_for_status()
            data = resp.json()
            return data["choices"][0]["message"]["content"]
        except httpx.TimeoutException:
            logger.warning(f"Kimi K3 timeout ({agent_tag})")
            return f"[Таймаут: Kimi K3 не ответил за {HTTP_TIMEOUT}s]"
        except httpx.HTTPStatusError as exc:
            body = exc.response.text[:200]
            logger.error(f"Kimi K3 HTTP error ({agent_tag})", extra={"status": exc.response.status_code, "body": body})
            return f"[Ошибка HTTP {exc.response.status_code}: Kimi K3]"
        except Exception as exc:
            logger.error(f"Kimi K3 error ({agent_tag})", extra={"error": str(exc)[:150]})
            return f"[Ошибка Kimi K3: {str(exc)[:100]}]"

    async def _ask_gemini(self, message: str, system_prompt: str,
                           url: str, agent_tag: str) -> str:
        """Запрос к Gemini через Google API (напрямую)."""
        if not GEMINI_KEY:
            return f"[GEMINI_API_KEY not set: {agent_tag}]"
        payload = {
            "contents": [
                {"role": "user", "parts": [{"text": f"{system_prompt}\n\n{message}"}]}
            ],
            "generationConfig": {
                "maxOutputTokens": 2048,
            },
        }
        try:
            resp = await self.http.post(url, json=payload,
                                         headers={"Content-Type": "application/json",
                                                   "x-goog-api-key": GEMINI_KEY},
                                         timeout=HTTP_TIMEOUT)
            resp.raise_for_status()
            data = resp.json()
            candidates = data.get("candidates", [])
            if candidates and candidates[0].get("content", {}).get("parts"):
                return candidates[0]["content"]["parts"][0]["text"]
            return "[Gemini: пустой ответ]"
        except httpx.TimeoutException:
            logger.warning(f"Gemini timeout ({agent_tag})")
            return f"[Таймаут: Gemini не ответил за {HTTP_TIMEOUT}s]"
        except httpx.HTTPStatusError as exc:
            body = exc.response.text[:200]
            logger.error(f"Gemini HTTP error ({agent_tag})", extra={"status": exc.response.status_code, "body": body})
            return f"[Ошибка HTTP {exc.response.status_code}: Gemini]"
        except Exception as exc:
            logger.error(f"Gemini error ({agent_tag})", extra={"error": str(exc)[:150]})
            return f"[Ошибка Gemini: {str(exc)[:100]}]"

    async def _researcher_step(self, message: str, cloud_position: str) -> str:
        """Qwen 3 Coder Researcher: поиск в Obsidian + DuckDuckGo + синтез контекста."""
        # Параллельный поиск контекста
        obsidian_context = ""
        web_context = ""

        async def search_obsidian() -> str:
            """Поиск в Obsidian по ключевым словам из запроса."""
            try:
                keywords = ' '.join(re.findall(r'\w{4,}', message)[:5])
                if keywords and state.obsidian and state.obsidian.available:
                    results = await state.obsidian.search(keywords)
                    if results:
                        return json.dumps([{"path": r.get("path", "?"), "content": r.get("content", "")[:200]}
                                           for r in results[:3]], ensure_ascii=False)
            except Exception:
                pass
            return ""

        async def search_web() -> str:
            """Поиск в DuckDuckGo по теме запроса."""
            try:
                ddg_resp = await self.http.post(
                    DDG_URL,
                    data={"q": message[:100]},
                    headers={"User-Agent": "Mozilla/5.0"},
                    timeout=8,
                )
                if ddg_resp.status_code == 200:
                    snippets = re.findall(
                        r'<a[^>]*class="result__a"[^>]*>(.*?)</a>\s*'
                        r'<a[^>]*class="result__snippet"[^>]*>(.*?)</a>',
                        ddg_resp.text, re.DOTALL
                    )
                    if snippets:
                        lines = []
                        for i, (title, snippet) in enumerate(snippets[:3]):
                            clean_title = re.sub(r'<[^>]+>', '', title).strip()
                            clean_snippet = re.sub(r'<[^>]+>', '', snippet).strip()
                            lines.append(f"{i+1}. {clean_title}: {clean_snippet[:200]}")
                        return '\n'.join(lines)
            except Exception:
                pass
            return ""

        obsidian_task = search_obsidian()
        web_task = search_web()
        obsidian_context, web_context = await asyncio.gather(obsidian_task, web_task, return_exceptions=True)

        obsidian_str = str(obsidian_context) if not isinstance(obsidian_context, BaseException) else ""
        web_str = str(web_context) if not isinstance(web_context, BaseException) else ""

        # Синтез контекста
        qwen_prompt = (
            "Ты — Researcher-агент Qwen 3. Твоя задача — собрать актуальный контекст "
            "для улучшения ответа консилиума.\n\n"
            f"Запрос пользователя: {message}\n\n"
            f"Облачная позиция: {cloud_position[:500]}\n\n"
        )
        if obsidian_str:
            qwen_prompt += f"Контекст из Obsidian (локальные заметки):\n{obsidian_str}\n\n"
        if web_str:
            qwen_prompt += f"Свежие результаты из DuckDuckGo:\n{web_str}\n\n"

        qwen_prompt += (
            "Выдели ключевые моменты и технологии, которые стоит учесть в финальном ответе. "
            "Будь краток (3-5 предложений)."
        )

        try:
            qwen_response = await self._ask_ollama(qwen_prompt, self.language_system, "qwen")
            return qwen_response
        except Exception as exc:
            logger.error("Qwen researcher failed", extra={"error": str(exc)[:150]})
            return "[Researcher: Qwen 3 временно недоступен]"

    async def _ask_ollama(self, message: str, system_prompt: str, agent_tag: str) -> str:
        """Запрос к локальной Ollama (Qwen 2.5 Coder 7B)."""
        payload = {
            "model": OLLAMA_MODEL_RESEARCHER,
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": message},
            ],
            "stream": False,
            "options": {"num_predict": 1024},
        }
        try:
            resp = await self.http.post(OLLAMA_CHAT_URL, json=payload, timeout=90)
            resp.raise_for_status()
            data = resp.json()
            return data["message"]["content"]
        except httpx.TimeoutException:
            logger.warning(f"Ollama timeout ({agent_tag})")
            return f"[Таймаут: {agent_tag} не ответил за 90s]"
        except httpx.HTTPStatusError as exc:
            body = exc.response.text[:200]
            logger.error(f"Ollama error ({agent_tag})", extra={"status": exc.response.status_code, "body": body})
            return f"[Ошибка Ollama: {exc.response.status_code}]"
        except Exception as exc:
            logger.error(f"Ollama error ({agent_tag})", extra={"error": str(exc)[:150]})
            return f"[Ошибка: {str(exc)[:100]}]"

    async def _fallback_local(self, message: str, system_prompt: str) -> str:
        """Фолбек к локальной модели при полном отказе консилиума."""
        prompt = f"{system_prompt}\n\n{message}"
        return await self._ask_ollama(prompt, self.language_system, "fallback")


# ─── Application state ─────────────────────────────────


class AppState:
    def __init__(self) -> None:
        self.online: bool = False
        self.started_at: datetime = datetime.now(timezone.utc)
        self.http_client: httpx.AsyncClient | None = None
        self.obsidian: ObsidianWorker | None = None

    @property
    def uptime_sec(self) -> int:
        return int((datetime.now(timezone.utc) - self.started_at).total_seconds())

    @property
    def provider(self) -> str:
        return "gemini" if self.online else "ollama"

    @property
    def obsidian_available(self) -> bool:
        return self.obsidian is not None and self.obsidian.available


state = AppState()

# ─── Lifespan ──────────────────────────────────────────


@asynccontextmanager
async def lifespan(app: FastAPI):
    state.http_client = httpx.AsyncClient(
        timeout=httpx.Timeout(HTTP_TIMEOUT),
        limits=httpx.Limits(max_keepalive_connections=10, max_connections=20),
    )
    state.obsidian = ObsidianWorker(
        base_url=OBSIDIAN_URL,
        api_key=OBSIDIAN_API_KEY,
    )
    state.online = await _check_network()

    # Пытаемся подключиться к Obsidian с авто-подбором порта
    obs_ok = await state.obsidian.ping()
    if not obs_ok:
        # Если не удалось — пробуем перебрать все стандартные варианты
        logger.info("Obsidian ping failed, trying all candidate URLs...")
        for url in ["http://127.0.0.1:27123", "https://127.0.0.1:27123",
                     "http://127.0.0.1:27124", "https://127.0.0.1:27124"]:
            if url == OBSIDIAN_URL:
                continue  # уже пробовали
            worker = ObsidianWorker(base_url=url, api_key=OBSIDIAN_API_KEY)
            ok = await worker.ping()
            if ok:
                state.obsidian = worker
                obs_ok = True
                logger.info("Obsidian reconnected", extra={"url": url})
                break
    # При старте восстанавливаем режим сессий
    if session_tracker.is_local_mode:
        logger.info("Starting in LOCAL autonomous mode (session limit reached previously)")
    else:
        logger.info("Starting in ONLINE mode", extra={
            "sessions_today": session_tracker.current,
            "max_per_day": SESSION_MAX_PER_DAY,
        })

    logger.info(
        "Started",
        extra={
            "online": True,
            "kimi_model": KIMI_MODEL,
            "gemini_key_set": bool(GEMINI_KEY),
            "researcher": OLLAMA_MODEL_RESEARCHER,
            "obsidian_ok": obs_ok,
            "pid": os.getpid(),
            "dev_mode": DEV_MODE,
            "session_mode": session_tracker.mode,
        },
    )
    yield
    if state.http_client:
        await state.http_client.aclose()
    if state.obsidian:
        await state.obsidian.close()
    logger.info("Stopped.")


app = FastAPI(
    title="coli-dev Orchestrator v4.0 — Коворкинг",
    version="4.0.0",
    description="Трёхуровневая архитектура консилиума v4.0: Генераторы + Kimi K3 Судья + Локальный Критик",
    lifespan=lifespan,
    docs_url="/docs" if DEV_MODE else None,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─── Rate Limiter ──────────────────────────────────────

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter


async def rate_limit_handler(request: Request, exc: RateLimitExceeded) -> JSONResponse:
    logger.warning("Rate limit exceeded", extra={"path": request.url.path})
    return JSONResponse(
        status_code=429,
        content=ErrorResponse(error="Too many requests. Please wait.", provider=state.provider, online=state.online).model_dump(),
        headers={"Retry-After": "6"},
    )


app.add_exception_handler(RateLimitExceeded, rate_limit_handler)

# ─── Middleware ────────────────────────────────────────


@app.middleware("http")
async def log_requests(request: Request, call_next) -> Response:
    rid = uuid.uuid4().hex[:16]
    token = _request_id.set(rid)
    started = datetime.now(timezone.utc)
    try:
        response: Response = await call_next(request)
        elapsed = int((datetime.now(timezone.utc) - started).total_seconds() * 1000)
        logger.info(
            f"{request.method} {request.url.path} → {response.status_code}",
            extra={"http_method": request.method, "http_path": request.url.path,
                   "http_status": response.status_code, "http_duration_ms": elapsed},
        )
        return response
    except Exception:
        elapsed = int((datetime.now(timezone.utc) - started).total_seconds() * 1000)
        logger.error(f"{request.method} {request.url.path} → 500",
                     extra={"http_duration_ms": elapsed}, exc_info=True)
        raise
    finally:
        _request_id.reset(token)


# ─── Helpers ───────────────────────────────────────────


async def _check_network() -> bool:
    """Проверка доступности облачных API."""
    if state.http_client is None:
        return False
    # Проверяем Google (для Gemini)
    if GEMINI_KEY:
        try:
            resp = await state.http_client.get(
                "https://generativelanguage.googleapis.com/v1beta/models",
                params={"key": GEMINI_KEY},
                timeout=NET_CHECK_TIMEOUT,
            )
            if resp.status_code == 200:
                logger.debug("Network check: Google Gemini ONLINE")
                return True
        except (httpx.TimeoutException, httpx.ConnectError, httpx.NetworkError):
            pass
    # Ollama проверяется отдельно. Наличие локальной модели не означает,
    # что облачные агенты доступны; иначе авто-маршрут зря запускал бы консилиум.
    logger.debug("Network check: OFFLINE")
    return False


async def _check_ollama() -> dict:
    result = {"available": False, "version": None, "models": None, "model_ready": None}
    if state.http_client is None:
        return result
    try:
        resp = await state.http_client.get(f"{OLLAMA_BASE}/api/version", timeout=2)
        if resp.status_code == 200:
            result["version"] = resp.json().get("version", "?")
    except Exception:
        pass
    try:
        resp = await state.http_client.get(f"{OLLAMA_BASE}/api/tags", timeout=2)
        if resp.status_code == 200:
            data = resp.json()
            models = [m["name"] for m in data.get("models", [])]
            result["models"] = models
            result["available"] = True
            result["model_ready"] = OLLAMA_MODEL_RESEARCHER in models
    except Exception:
        pass
    return result


async def _stream_answer_debate(answer: str, debate_html: str, provider: str, model: str):
    """Универсальный SSE-стример: сначала лог дебатов, затем токены ответа."""
    # Сначала лог дебатов
    yield f"data: {json.dumps({'type': 'debate_log', 'html': debate_html}, ensure_ascii=False)}\n\n"

    # Потом стримим ответ слово за словом
    started = datetime.now(timezone.utc)
    tokens = 0
    try:
        words = answer.split(" ")
        for i, word in enumerate(words):
            tokens += 1
            yield f"data: {json.dumps({'type': 'token', 'content': word + (' ' if i < len(words) - 1 else '')}, ensure_ascii=False)}\n\n"
            await asyncio.sleep(0.005)

        elapsed = int((datetime.now(timezone.utc) - started).total_seconds() * 1000)
        yield f"data: {json.dumps({'type': 'done', 'provider': provider, 'model': model,
                                     'duration_ms': elapsed, 'tokens': tokens})}\n\n"
    except Exception as exc:
        logger.error("Stream error", extra={"error": str(exc)[:200]})
        yield f"data: {json.dumps({'type': 'error', 'error': str(exc)[:300], 'provider': provider})}\n\n"


# ─── UI HTML ────────────────────────────────────────────

UI_HTML = Path(__file__).resolve().parent.joinpath("ui.html").read_text(encoding="utf-8")


# ─── Exception handler ────────────────────────────────


@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException) -> Response:
    return Response(
        status_code=exc.status_code,
        media_type="application/json",
        content=ErrorResponse(
            error=exc.detail,
            provider=state.provider,
            online=state.online,
        ).model_dump_json(),
    )


# ─── UI Endpoints ──────────────────────────────────────


@app.get("/", response_class=HTMLResponse)
async def chat_ui():
    return UI_HTML


# ─── API Endpoints ─────────────────────────────────────


@app.get("/api/status")
async def api_status():
    session_status = session_tracker.get_status()
    return {
        "service": "coli-dev Orchestrator v4.0",
        "version": "4.0.0",
        "online": True,
        "provider": "consilium",
        "kimi_model": KIMI_MODEL,
        "gemini_key_set": bool(GEMINI_KEY),
        "researcher": OLLAMA_MODEL_RESEARCHER,
        "session": session_status,
    }


@app.get("/health")
async def health():
    net_ok, ollama_info = await asyncio.gather(
        _check_network(),
        _check_ollama(),
    )
    state.online = net_ok
    session_status = session_tracker.get_status()

    return HealthResponse(
        status="ok" if (net_ok or ollama_info["available"]) else "degraded",
        online=net_ok,
        provider=state.provider,
        gemini_model="gemini-3-flash / gemini-3.1-pro",
        ollama_model=OLLAMA_MODEL_RESEARCHER,
        ollama_available=ollama_info["available"],
        ollama_version=ollama_info["version"],
        ollama_models=ollama_info["models"],
        ollama_model_ready=ollama_info["model_ready"],
        uptime_sec=state.uptime_sec,
        session_mode=session_status["mode"],
        session_current=session_status["current"],
        session_max=session_status["max"],
    )


@app.get("/api/session")
async def get_session_status():
    """Получить статус сессий Freebuff."""
    return session_tracker.get_status()


@app.post("/api/session/reset")
async def reset_session():
    """Сбросить режим в онлайн (для администратора)."""
    session_tracker.reset_mode()
    logger.info("Session mode reset to online")
    return {"status": "ok", "mode": "online"}


# ─── Streaming Chat (Consilium) ────────────────────────


@app.post("/chat/stream")
@limiter.limit(CHAT_RATE_LIMIT)
async def chat_stream(request: Request, req: ChatRequest):
    """
    Streaming chat с двухуровневым консилиумом (SSE).

    УРОВЕНЬ 1: Cloud Code (Gemini + GLM)
    УРОВЕНЬ 2: Консилиум (Freebuff + Qwen 3)

    Если лимит сессий исчерпан → автономный локальный режим (Qwen 3).
    """
    if req.mode == "local":
        logger.info("Stream → USER_SELECTED_LOCAL", extra={"mode": "local"})
        return await _handle_local_stream(req)

    state.online = await _check_network()

    # Автоматический маршрут: консилиум при доступной сети/квоте, иначе Ollama.
    if state.online and session_tracker.can_start_session():
        try:
            session_tracker.start_session()
            logger.info("Stream → CONSILIUM (multi-agent debate)",
                         extra={"session_count": session_tracker.current, "mode": "online"})
            return await _handle_consilium_stream(req)
        except Exception as exc:
            logger.warning("Consilium failed, falling back to LOCAL", extra={"error": str(exc)[:100]})
            session_tracker.reset_mode()

    logger.info("Stream → LOCAL (offline or automatic fallback)",
                 extra={"session_count": session_tracker.current, "mode": "local"})
    return await _handle_local_stream(req)


async def _handle_consilium_stream(req: ChatRequest) -> StreamingResponse:
    """Обработка через двухуровневый консилиум."""
    engine = ConsiliumEngine(state.http_client, req.language)
    answer, debate_log = await engine.run(req.message, req.system_prompt)
    debate_html = debate_log.to_html()

    return StreamingResponse(
        _stream_answer_debate(answer, debate_html, "consilium", "multi-agent"),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        },
    )


async def _handle_local_stream(req: ChatRequest) -> StreamingResponse:
    """Обработка через локальный Digital Twin (Qwen 3)."""
    engine = ConsiliumEngine(state.http_client, req.language)
    answer, debate_log = await engine.run_local(req.message, req.system_prompt)
    debate_html = debate_log.to_html()

    return StreamingResponse(
        _stream_answer_debate(answer, debate_html, "local", OLLAMA_MODEL_RESEARCHER),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        },
    )


# ─── Obsidian API endpoints ──────────────────────────


class ObsidianWriteRequest(BaseModel):
    content: str


class ObsidianSearchRequest(BaseModel):
    query: str


@app.get("/obsidian/ping")
async def obsidian_ping():
    if not state.obsidian_available:
        raise HTTPException(status_code=503, detail="Obsidian not configured (set OBSIDIAN_API_KEY)")
    ok = await state.obsidian.ping()
    return {"ok": ok, "url": state.obsidian.base_url or OBSIDIAN_URL}


@app.get("/obsidian/list")
async def obsidian_list(path: str = ""):
    if not state.obsidian_available:
        raise HTTPException(status_code=503, detail="Obsidian not configured")
    try:
        files = await state.obsidian.list_files(path)
        return {"files": files, "count": len(files)}
    except ConnectionError as exc:
        raise HTTPException(status_code=502, detail=str(exc))


@app.get("/obsidian/read/{path:path}")
async def obsidian_read(path: str):
    if not state.obsidian_available:
        raise HTTPException(status_code=503, detail="Obsidian not configured")
    try:
        data = await state.obsidian.read(path)
        return data
    except ConnectionError as exc:
        msg = str(exc)
        if "404" in msg or "не найден" in msg:
            raise HTTPException(status_code=404, detail=f"File not found: {path}")
        raise HTTPException(status_code=502, detail=msg)


@app.put("/obsidian/write/{path:path}")
async def obsidian_write(path: str, req: ObsidianWriteRequest):
    if not state.obsidian_available:
        raise HTTPException(status_code=503, detail="Obsidian not configured")
    try:
        result = await state.obsidian.write(path, req.content)
        logger.info("Obsidian wrote", extra={"path": path, "chars": len(req.content), "ok": True})
        return {"ok": True, "path": path, "size": len(req.content), "result": result}
    except ConnectionError as exc:
        raise HTTPException(status_code=502, detail=str(exc))


@app.delete("/obsidian/delete/{path:path}")
async def obsidian_delete(path: str):
    if not state.obsidian_available:
        raise HTTPException(status_code=503, detail="Obsidian not configured")
    try:
        result = await state.obsidian.delete(path)
        logger.info("Obsidian deleted", extra={"path": path, "ok": True})
        return {"ok": True, "path": path, "result": result}
    except ConnectionError as exc:
        msg = str(exc)
        if "404" in msg or "не найден" in msg:
            raise HTTPException(status_code=404, detail=f"File not found: {path}")
        raise HTTPException(status_code=502, detail=msg)


@app.post("/obsidian/search")
async def obsidian_search(req: ObsidianSearchRequest):
    if not state.obsidian_available:
        raise HTTPException(status_code=503, detail="Obsidian not configured")
    try:
        results = await state.obsidian.search(req.query)
        return {"results": results, "count": len(results), "query": req.query}
    except ConnectionError as exc:
        raise HTTPException(status_code=502, detail=str(exc))


# ─── Entry point ──────────────────────────────────────

if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        app,
        host=HOST,
        port=PORT,
        reload=DEV_MODE,
        log_level="warning",
        access_log=False,
    )
