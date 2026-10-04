#!/bin/bash
# ============================================================
# start.sh — Единое меню запуска coli-dev
# ============================================================
# Выбери режим:
#   1) Kimi Code   — Kimi K3 (Moonshot AI)
#   2) Claude Code  — Gemini 3.5 Flash (Google)
#   3) Консилиум    — Полная архитектура (Kimi + Gemini + Freebuff)
#   4) Оркестратор  — Веб-API сервер
# ============================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

clear

echo -e "${MAGENTA}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║           🧠 coli-dev — AI Code Assistant               ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "  ${CYAN}Выбери режим работы:${NC}"
echo ""
echo -e "  ${GREEN}1)${NC} 🦊 ${MAGENTA}Kimi Code${NC}    — Kimi K3 (Moonshot AI)"
echo -e "  ${GREEN}2)${NC} 🤖 ${CYAN}Claude Code${NC}  — Gemini 3.5 Flash (Google AI)"
echo -e "  ${GREEN}3)${NC} 🧠 ${YELLOW}Консилиум${NC}    — Полная архитектура (Kimi + Gemini + Freebuff)"
echo -e "  ${GREEN}4)${NC} 🌐 ${GREEN}Оркестратор${NC}  — Веб-API сервер (localhost:8000)"
echo -e "  ${GREEN}0)${NC} ❌ Выход"
echo ""
echo -e "  ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
read -p "  👉 Введи номер (0-4): " choice

case $choice in
    1)
        echo ""
        echo -e "  ${MAGENTA}🚀 Запуск Kimi Code (Kimi K3)...${NC}"
        echo ""
        bash "$SCRIPT_DIR/start_kimi_code.sh"
        ;;
    2)
        echo ""
        echo -e "  ${CYAN}🚀 Запуск Claude Code (Gemini 3.5 Flash)...${NC}"
        echo ""
        bash "$SCRIPT_DIR/start_claude.sh"
        ;;
    3)
        echo ""
        echo -e "  ${YELLOW}🚀 Запуск полного консилиума...${NC}"
        echo ""
        # Консилиум = Kimi Code в фоне + веб-интерфейс
        echo -e "  ${CYAN}📌 Режим консилиума:${NC}"
        echo -e "  ${GREEN}→${NC} Kimi K3 = Верховный Судья"
        echo -e "  ${GREEN}→${NC} Gemini 3.5 Flash + GLM 5.2 = Генераторы"
        echo -e "  ${GREEN}→${NC} Freebuff (Mimo 2.5) = Критик"
        echo -e "  ${GREEN}→${NC} Qwen 2.5 Coder = Верификатор"
        echo ""
        echo -e "  ${CYAN}Открой в браузере: http://127.0.0.1:8000${NC}"
        echo ""
        bash "$SCRIPT_DIR/start_v4.sh"
        ;;
    4)
        echo ""
        echo -e "  ${GREEN}🚀 Запуск оркестратора (веб-API)...${NC}"
        echo ""
        echo -e "  ${CYAN}📌 API:${NC}"
        echo -e "  ${GREEN}→${NC} Chat:    POST /chat/stream"
        echo -e "  ${GREEN}→${NC} Status:  GET  /api/status"
        echo -e "  ${GREEN}→${NC} Health:  GET  /health"
        echo -e "  ${GREEN}→${NC} Docs:    http://127.0.0.1:8000/docs"
        echo ""
        bash "$SCRIPT_DIR/start_v4.sh"
        ;;
    0|q|Q)
        echo ""
        echo -e "  ${RED}👋 Пока!${NC}"
        exit 0
        ;;
    *)
        echo ""
        echo -e "  ${RED}❌ Неверный выбор: $choice${NC}"
        echo -e "  ${YELLOW}Попробуй снова: bash start.sh${NC}"
        exit 1
        ;;
esac
