#!/usr/bin/env python3
"""
🚀 start_server.py — Запуск orchestrator (без bash)

Запуск (одна команда — скопируй в терминал):
    .venv/bin/python start_server.py
"""
import os
import sys
import subprocess
from pathlib import Path

PROJECT_DIR = Path(__file__).resolve().parent
VENV_PYTHON = PROJECT_DIR / ".venv" / "bin" / "python"
MAIN_FILE = PROJECT_DIR / "01_Projects" / "orchestrator.py"

if not MAIN_FILE.exists():
    print(f"  ❌ Файл {MAIN_FILE} не найден!")
    sys.exit(1)

if not VENV_PYTHON.exists():
    print(f"  ❌ .venv не найден! Создай: python3 -m venv .venv")
    sys.exit(1)

print("=" * 50)
print("  🚀 ЗАПУСК COLI-DEV ORCHESTRATOR")
print(f"  📂 {MAIN_FILE}")
print(f"  🌐 http://127.0.0.1:8000")
print(f"  🖥  http://127.0.0.1:8000/ui")
print(f"  📋 http://127.0.0.1:8000/docs")
print(f"  🧪 .venv/bin/python -m pytest 01_Projects/test_orchestrator.py -v")
print("  Нажми Ctrl+C чтобы остановить")
print("=" * 50)
print()

os.chdir(str(PROJECT_DIR))
subprocess.run([str(VENV_PYTHON), str(MAIN_FILE)])
print("\n  Сервер остановлен.")
