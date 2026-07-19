#!/usr/bin/env python3
"""
🔍 check_all.py — Полная проверка проекта coli-dev

Запуск:
    .venv/bin/python check_all.py
"""
import os
import sys
import json
import urllib.request
import urllib.error
from pathlib import Path

PROJECT_DIR = Path(__file__).resolve().parent
errors = 0
warnings = 0


def ok(name: str, detail: str = ""):
    print(f"  ✅ {name}" + (f" — {detail}" if detail else ""))


def fail(name: str, detail: str):
    global errors
    print(f"  ❌ {name} — {detail}")
    errors += 1


def warn(name: str, detail: str):
    global warnings
    print(f"  ⚠️  {name} — {detail}")
    warnings += 1


print("=" * 50)
print("  🔍 ПРОВЕРКА ПРОЕКТА coli-dev")
print("=" * 50)
print()

# ─── 1. Python ────────────────────────────────────────
print("📌 1. Python")
ok("Python", sys.executable)
ok(f"Версия {sys.version.split()[0]}", sys.platform)

# ─── 2. .venv ─────────────────────────────────────────
print("\n📌 2. Виртуальное окружение")
venv = PROJECT_DIR / ".venv"
venv_python = venv / "bin" / "python"
if venv.exists() and venv_python.exists():
    ok(".venv существует")
else:
    fail(".venv", "ОТСУТСТВУЕТ — python3 -m venv .venv")

if sys.prefix == sys.base_prefix:
    warn("Запуск не из .venv", "Используй: .venv/bin/python check_all.py")

# ─── 3. .env ─────────────────────────────────────────
print("\n📌 3. API-ключи (.env)")
or_key = ""
gemini_key = ""
env_file = PROJECT_DIR / ".env"

if env_file.exists():
    ok(".env существует")
    with open(env_file) as f:
        lines = f.readlines()
    for line in lines:
        if line.startswith("OPENROUTER_API_KEY="):
            or_key = line.split("=", 1)[1].strip().strip('"').strip("'")
        elif line.startswith("GEMINI_API_KEY="):
            gemini_key = line.split("=", 1)[1].strip().strip('"').strip("'")
else:
    fail(".env", "ОТСУТСТВУЕТ — cp .env.example .env и заполни ключи")

if or_key and not or_key.startswith("твой"):
    ok("OPENROUTER_API_KEY", f"{or_key[:15]}...")
    if or_key.startswith("sk-or-"):
        ok("Формат OpenRouter OK")
    else:
        warn("Формат OpenRouter", "должен начинаться с sk-or-")
else:
    fail("OPENROUTER_API_KEY", "ОТСУТСТВУЕТ — добавь в .env из openrouter.ai/keys")

if gemini_key and not gemini_key.startswith("твой"):
    ok("GEMINI_API_KEY", f"{gemini_key[:12]}...")
else:
    warn("GEMINI_API_KEY", "не установлен (необязательно для Claude Code)")

# ─── 4. OpenRouter API тест ───────────────────────────
print("\n📌 4. OpenRouter API")
if or_key and or_key.startswith("sk-or-"):
    try:
        # Быстрый тест: отправляем 1 токен к Gemini
        data = json.dumps({
            "model": "google/gemini-3.5-flash",
            "messages": [{"role": "user", "content": "hi"}],
            "max_tokens": 1
        }).encode()
        req = urllib.request.Request(
            "https://openrouter.ai/api/v1/chat/completions",
            data=data,
            headers={
                "Authorization": f"Bearer {or_key}",
                "Content-Type": "application/json"
            }
        )
        with urllib.request.urlopen(req, timeout=10) as resp:
            result = json.loads(resp.read().decode())
            if "choices" in result:
                ok("Gemini 3.5 Flash отвечает!", "✅ КЛЮЧ РАБОЧИЙ!")
            else:
                warn("OpenRouter ответил", str(result)[:100])
    except urllib.error.HTTPError as e:
        body = e.read().decode()[:200]
        fail("OpenRouter", f"ОШИБКА {e.code}: {body}")
    except Exception as e:
        fail("OpenRouter", f"ОШИБКА: {e}")
else:
    warn("OpenRouter тест пропущен", "нет ключа")

# ─── 5. Зависимости ───────────────────────────────────
print("\n📌 5. Зависимости")
try:
    import fastapi
    ok("FastAPI", fastapi.__version__)
except ImportError:
    fail("FastAPI", "не установлен — .venv/bin/pip install fastapi")

try:
    import uvicorn
    ok("Uvicorn", uvicorn.__version__)
except ImportError:
    fail("Uvicorn", "не установлен — .venv/bin/pip install 'uvicorn[standard]'")

# ─── 6. main.py ───────────────────────────────────────
print("\n📌 6. FastAPI приложение")
main_file = PROJECT_DIR / "01_Projects" / "fastapi_app" / "main.py"
if main_file.exists():
    ok("main.py существует")
    content = main_file.read_text()
    endpoints = []
    for line in content.split("\n"):
        for method in ["get", "post", "put", "delete"]:
            if f"@app.{method}(" in line:
                path = line.split('"')[1] if '"' in line else ""
                endpoints.append(f"{method.upper()} {path}")
    for ep in endpoints:
        ok(ep)
else:
    fail("main.py", "ОТСУТСТВУЕТ")

# ─── 7. start_claude.sh ───────────────────────────────
print("\n📌 7. Claude Code")
sh_file = PROJECT_DIR / "start_claude.sh"
if sh_file.exists():
    ok("start_claude.sh существует")
    content = sh_file.read_text()
    if "google/gemini-3.5-flash" in content:
        ok("Модель: google/gemini-3.5-flash")
    if "openrouter.ai" in content:
        ok("Провайдер: OpenRouter")
else:
    fail("start_claude.sh", "ОТСУТСТВУЕТ")

# ─── 8. test_api.py ───────────────────────────────────
print("\n📌 8. Тест-скрипты")
test_file = PROJECT_DIR / "01_Projects" / "fastapi_app" / "test_api.py"
if test_file.exists():
    ok("test_api.py")
srv_file = PROJECT_DIR / "start_server.py"
if srv_file.exists():
    ok("start_server.py")

# ─── ИТОГИ ────────────────────────────────────────────
print()
print("=" * 50)
if errors == 0:
    if warnings == 0:
        print("  🎯 ВСЁ ИДЕАЛЬНО! Вперёд! 🚀")
    else:
        print(f"  ✅ Готово! {warnings} предупреждений — можно работать")
else:
    print(f"  ❌ {errors} ошибок — исправь перед запуском")
print("=" * 50)
