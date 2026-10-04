"""
obsidian_worker.py — интеграция с Obsidian Local REST API.

Плагин: Local REST API with MCP (coddingtonbear/obsidian-local-rest-api)
Порт по умолчанию: 27124 (HTTPS, self-signed cert)
Аутентификация: Bearer token (из настроек плагина)

Фичи:
  - Автоподбор порта (27123 → 27124) и протокола (HTTPS → HTTP)
  - verify=False для self-signed сертификата
  - Graceful fallback — возвращает понятные сообщения, не 502

Использование:
    worker = ObsidianWorker(base_url=None, api_key="...")
    await worker.ping()  # авто-подбор порта
    await worker.list_files()
    await worker.read("note.md")
"""

from __future__ import annotations

import logging
from typing import Any

import httpx

logger = logging.getLogger("colidev.obsidian")

# Варианты подключения: HTTP 27123 — приоритет (пользователь переключил плагин в HTTP)
# Порядок: http://127.0.0.1:27123 первый, затем запасные варианты
_DEFAULT_CANDIDATES = [
    "http://127.0.0.1:27123",
    "http://127.0.0.1:27124",
    "https://127.0.0.1:27123",
    "https://127.0.0.1:27124",
]


class ObsidianWorker:
    """Асинхронный клиент для Obsidian Local REST API с авто-подбором порта."""

    def __init__(
        self,
        base_url: str | None = None,
        api_key: str = "",
        timeout: float = 10.0,
    ) -> None:
        self.api_key = api_key
        self._api_key_ok = bool(api_key)
        self._timeout = timeout
        self._working_url: str | None = None
        self._last_error: str | None = None

        # Если base_url передан явно — используем его
        self._candidates = [base_url] if base_url else list(_DEFAULT_CANDIDATES)

        # Self-signed cert — отключаем проверку для локального dev
        self._client = httpx.AsyncClient(
            verify=False,
            timeout=httpx.Timeout(timeout),
            limits=httpx.Limits(max_keepalive_connections=2, max_connections=5),
        )

    async def close(self) -> None:
        """Закрыть HTTP-клиент."""
        await self._client.aclose()

    @property
    def available(self) -> bool:
        """Проверить, сконфигурирован ли ключ и найден ли порт."""
        return self._api_key_ok and self._working_url is not None

    @property
    def configured(self) -> bool:
        """Проверить, задан ли API-ключ, даже если Obsidian пока не запущен."""
        return self._api_key_ok

    @property
    def base_url(self) -> str | None:
        """Рабочий URL (после авто-подбора)."""
        return self._working_url

    @property
    def last_error(self) -> str | None:
        """Последняя ошибка подключения (для вывода пользователю)."""
        return self._last_error

    # ─── Проверка соединения ──────────────────────────

    async def ping(self) -> bool:
        """Проверить, отвечает ли Obsidian API.

        Перебирает кандидаты (27123→27124, https→http) пока не найдёт
        работающий URL.
        """
        if not self._api_key_ok:
            self._last_error = "OBSIDIAN_API_KEY не настроен в .env"
            return False

        # Если уже знаем рабочий URL — просто проверяем
        if self._working_url:
            ok = await self._try_ping(self._working_url)
            if ok:
                return True
            # Упал — сбрасываем и перебираем заново
            self._working_url = None

        # Перебор кандидатов
        errors: list[str] = []
        for url in self._candidates:
            ok = await self._try_ping(url)
            if ok:
                self._working_url = url
                self._last_error = None
                logger.info("Obsidian connected", extra={"url": url})
                return True
            errors.append(f"{url}: {self._last_error}")

        self._last_error = (
            f"Не удалось подключиться к Obsidian. "
            f"Проверьте что плагин Local REST API включён. "
            f"Пробовал: {'; '.join(errors[:3])}..."
        )
        logger.warning("Obsidian unavailable", extra={"errors": errors})
        return False

    async def _try_ping(self, url: str) -> bool:
        """Проверить конкретный URL."""
        auth_header = {"Authorization": f"Bearer {self.api_key}"}
        logger.debug("Trying Obsidian ping", extra={"url": url, "has_key": bool(self.api_key)})
        try:
            resp = await self._client.get(
                f"{url}/vault/",
                headers=auth_header,
                timeout=3,
            )
            ok = resp.status_code == 200
            if not ok:
                self._last_error = f"HTTP {resp.status_code}"
                logger.debug("Obsidian ping failed", extra={"url": url, "status": resp.status_code})
            else:
                logger.info("Obsidian ping OK", extra={"url": url})
            return ok
        except httpx.ConnectError:
            self._last_error = "Connection refused"
            logger.debug("Obsidian connection refused", extra={"url": url})
            return False
        except httpx.TimeoutException:
            self._last_error = "Timeout"
            return False
        except Exception as exc:
            self._last_error = str(exc)[:100]
            return False

    def _headers(self) -> dict[str, str]:
        """Заголовки авторизации для Obsidian API.
        
        Всегда передаёт Bearer-токен из OBSIDIAN_API_KEY.
        """
        if not self.api_key:
            logger.warning("Obsidian: empty API key, Authorization header omitted")
        return {"Authorization": f"Bearer {self.api_key}"}

    def _check_ready(self) -> None:
        """Проверить что порт найден и ключ настроен."""
        if not self._api_key_ok:
            raise ConnectionError(
                "Obsidian недоступен. OBSIDIAN_API_KEY не настроен в .env."
            )
        if not self._working_url:
            raise ConnectionError(
                "Obsidian недоступен. Плагин Local REST API не отвечает. "
                "Проверьте: 1) плагин установлен и включён 2) Obsidian запущен"
            )

    # ─── CRUD: файлы с graceful fallback ───────────────

    async def _request(
        self,
        method: str,
        endpoint: str,
        **kwargs: Any,
    ) -> dict[str, Any]:
        """Выполнить HTTP-запрос к Obsidian с единой обработкой ошибок.

        Возвращает JSON-ответ.
        Рейзит ConnectionError с понятным сообщением при ошибке.
        """
        if self._api_key_ok and not self._working_url:
            connected = await self.ping()
            if not connected:
                self._check_ready()
        self._check_ready()
        url = f"{self._working_url}/{endpoint.lstrip('/')}"
        headers = self._headers()
        if "headers" in kwargs:
            headers.update(kwargs.pop("headers"))

        try:
            resp = await self._client.request(method, url, headers=headers, **kwargs)
            resp.raise_for_status()
            return resp.json() if resp.content else {}
        except httpx.ConnectError:
            self._working_url = None  # сбрасываем — возможно Obsidian перезапущен
            raise ConnectionError(
                "Obsidian не отвечает на запрос. "
                "Убедитесь что Obsidian запущен и плагин Local REST API включён."
            )
        except httpx.HTTPStatusError as exc:
            if exc.response.status_code == 404:
                raise ConnectionError("Файл не найден (404)")
            raise ConnectionError(
                f"Obsidian вернул ошибку HTTP {exc.response.status_code}. "
                f"Возможно плагин Local REST API отключён или заблокирован системой."
            )
        except httpx.TimeoutException:
            raise ConnectionError(
                "Obsidian превысил таймаут. Проверьте соединение."
            )
        except Exception as exc:
            raise ConnectionError(
                f"Ошибка Obsidian: {str(exc)[:200]}"
            )

    async def list_files(self, path: str = "") -> list[Any]:
        """Получить список файлов в vault (рекурсивно)."""
        data = await self._request("GET", f"vault/{path.lstrip('/')}")
        if isinstance(data, dict):
            # Obsidian API возвращает {"files": [...]}
            files_data = data.get("files", data)
            if isinstance(files_data, list):
                return files_data
        return data if isinstance(data, list) else [data]

    async def read(self, path: str) -> dict[str, Any]:
        """Прочитать содержимое файла."""
        return await self._request("GET", f"vault/{path.lstrip('/')}")

    async def write(
        self,
        path: str,
        content: str,
        content_type: str = "text/markdown",
    ) -> dict[str, Any]:
        """Создать или перезаписать файл."""
        return await self._request(
            "PUT",
            f"vault/{path.lstrip('/')}",
            content=content,
            headers={"Content-Type": content_type},
        )

    async def delete(self, path: str) -> dict[str, Any]:
        """Удалить файл."""
        return await self._request("DELETE", f"vault/{path.lstrip('/')}")

    # ─── Поиск ────────────────────────────────────────

    async def search(self, query: str, context_length: int = 200) -> list[dict[str, Any]]:
        """Полнотекстовый поиск по vault с контекстом вокруг совпадений."""
        normalized_query = query.strip()
        if not normalized_query:
            return []

        result = await self._request(
            "POST",
            "search/simple/",
            params={
                "query": normalized_query,
                "contextLength": max(40, min(int(context_length), 1000)),
            },
        )
        return result if isinstance(result, list) else []

    # ─── Команды ──────────────────────────────────────

    async def list_commands(self) -> list[dict[str, Any]]:
        """Получить список доступных команд Obsidian."""
        return await self._request("GET", "commands/")

    async def execute_command(self, command_id: str) -> dict[str, Any]:
        """Выполнить команду Obsidian по ID."""
        return await self._request("POST", f"commands/{command_id}/")
