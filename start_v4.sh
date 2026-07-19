#!/bin/bash
# coli-dev v4.0 — Коворкинг
# Запуск: bash start_v4.sh

cd "$(dirname "$0")/01_Projects"
source ../.venv/bin/activate

echo "🧠 coli-dev v4.0 — Коворкинг"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌐 http://127.0.0.1:8000"
echo "📚 http://127.0.0.1:8000/docs (DEV_MODE)"
echo "⏹  Ctrl+C — остановить"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━"

python -m uvicorn orchestrator:app --host 127.0.0.1 --port 8000
