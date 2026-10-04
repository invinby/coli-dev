#!/bin/bash
# ============================================================
# start_claude.sh — Запуск Claude Code через Gemini 3.5 Flash
# ============================================================
# Как это работает:
#   Claude Code → Anthropic формат → LiteLLM (localhost:4000)
#                                   → Google Gemini API (напрямую)
#
# LiteLLM — прокси, переводящий форматы между Claude и Gemini.
#
# Требуется:
#   1. GEMINI_API_KEY в .env (ключ Google AI Studio)
#   2. litellm установлен: .venv/bin/pip install 'litellm[proxy]'
# ============================================================

set -euo pipefail

# Переходим в папку скрипта (чтобы относительные пути работали)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# ============================================================
# 🔐 Загрузка API-ключей из .env
# ============================================================
if [ -f ".env" ]; then
    echo "  📄 Загружаю .env..."
    set -a
    source .env
    set +a
else
    echo "  ⚠️  Файл .env не найден!"
    cp -n .env.example .env 2>/dev/null || true
    if [ -f ".env" ]; then
        echo "  ✅ Создан .env из .env.example"
        echo "  📋 Отредактируй .env, вставь свои API-ключи и запусти заново."
    fi
    exit 1
fi

# Проверяем GEMINI_API_KEY
if [ -z "${GEMINI_API_KEY:-}" ]; then
    echo "  ❌ GEMINI_API_KEY не найден в .env!"
    echo "  📋 Получи ключ: https://aistudio.google.com/app/apikey"
    echo "  📋 Добавь в .env: GEMINI_API_KEY=\"твой_ключ\""
    exit 1
fi

# Проверяем, что claude установлен
if ! command -v claude &>/dev/null; then
    echo "  ❌ Claude Code не установлен!"
    echo "  📋 Установи: npm install -g @anthropic-ai/claude-code"
    exit 1
fi

# ============================================================
# ✅ Проверка .venv
# ============================================================
LITELLM_PORT=4000
VENV_PYTHON=".venv/bin/python"

if [ ! -f "$VENV_PYTHON" ]; then
    echo "  ❌ .venv не найден!"
    echo "  📋 Создай: python3 -m venv .venv && source .venv/bin/activate"
    exit 1
fi

if ! $VENV_PYTHON -c "import litellm" 2>/dev/null; then
    echo "  ⚠️  LiteLLM не установлен. Устанавливаю..."
    $VENV_PYTHON -m pip install 'litellm[proxy]' 2>&1 | tail -5
    if ! $VENV_PYTHON -c "import litellm" 2>/dev/null; then
        echo "  ❌ Не удалось установить LiteLLM"
        exit 1
    fi
    echo "  ✅ LiteLLM установлен!"
fi

# ============================================================
# 🧹 Cleanup при выходе
# ============================================================
cleanup() {
    echo ""
    echo "  🛑 Останавливаю LiteLLM..."
    kill $LITELLM_PID 2>/dev/null || true
    wait $LITELLM_PID 2>/dev/null || true
    echo "  ✅ Готово!"
}
trap cleanup EXIT INT TERM

# ============================================================
# 🚀 Запуск LiteLLM в фоне (напрямую к Google Gemini)
# ============================================================
echo "  🚀 Запускаю LiteLLM на порту $LITELLM_PORT..."
$VENV_PYTHON -m litellm \
    --model gemini/gemini-3.5-flash \
    --port $LITELLM_PORT \
    --num_workers 1 \
    &>/tmp/litellm.log &
LITELLM_PID=$!

# Ждём пока LiteLLM запустится
echo "  ⏳ Ожидание запуска..."
for i in $(seq 1 15); do
    sleep 1
    if curl -s http://127.0.0.1:$LITELLM_PORT/health >/dev/null 2>&1; then
        echo "  ✅ LiteLLM запущен!"
        break
    fi
    if [ $i -eq 15 ]; then
        echo "  ❌ LiteLLM не запустился за 15с. Лог:"
        cat /tmp/litellm.log 2>/dev/null | tail -5
        kill $LITELLM_PID 2>/dev/null
        exit 1
    fi
done

# ============================================================
# 🚀 Настройка Claude Code на LiteLLM + Google Gemini
# ============================================================
export ANTHROPIC_BASE_URL="http://127.0.0.1:$LITELLM_PORT"
export ANTHROPIC_API_KEY="$GEMINI_API_KEY"
export ANTHROPIC_MODEL="gemini/gemini-3.5-flash"

echo "======================================"
echo "  🚀 Запуск Claude Code + Gemini 3.5 Flash"
echo "======================================"
echo "  Модель:   Gemini 3.5 Flash (Google AI)"
echo "  Прокси:   http://127.0.0.1:$LITELLM_PORT"
echo "  API Key:  ${GEMINI_API_KEY:0:12}..."
echo "  Папка:    $(pwd)"
echo "======================================"
echo ""

# Запускаем Claude Code
claude "$@"
