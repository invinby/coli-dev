#!/bin/bash
# ============================================================
# start_kimi_code.sh — Запуск Kimi Code CLI с моделью Kimi K3
# ============================================================
# Как это работает:
#   Kimi Code CLI → Moonshot API → Kimi K3 модель
#
# Требуется:
#   1. KIMI_API_KEY в .env (ключ Moonshot AI)
#   2. kimi-cli установлен: pip3 install kimi-cli
# ============================================================

set -euo pipefail

# Переходим в папку скрипта
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

# Проверяем KIMI_API_KEY
if [ -z "${KIMI_API_KEY:-}" ]; then
    echo "  ❌ KIMI_API_KEY не найден в .env!"
    echo "  📋 Получи ключ: https://platform.kimi.ai/"
    echo "  📋 Добавь в .env: KIMI_API_KEY=\"твой_ключ\""
    exit 1
fi

# Проверяем, что kimi установлен
if ! command -v kimi &>/dev/null; then
    echo "  ❌ Kimi Code CLI не установлен!"
    echo "  📋 Установи: pip3 install kimi-cli"
    exit 1
fi

# ============================================================
# 🚀 Настройка Kimi Code на Moonshot API
# ============================================================
export MOONSHOT_API_KEY="$KIMI_API_KEY"
export MOONSHOT_BASE_URL="https://api.moonshot.cn/v1"

echo "======================================"
echo "  🚀 Запуск Kimi Code CLI (Kimi K3)"
echo "======================================"
echo "  Модель:  moonshot-v1-auto (Kimi K3)"
echo "  API:     https://api.moonshot.cn/v1"
echo "  Key:     ${KIMI_API_KEY:0:12}..."
echo "  Папка:   $(pwd)"
echo "======================================"
echo ""
echo "  💡 Команды:"
echo "     /help     — справка"
echo "     /logout   — выйти из аккаунта"
echo "     Ctrl+C    — выход"
echo ""

# Запускаем Kimi Code
kimi "$@"
