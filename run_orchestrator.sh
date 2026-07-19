#!/bin/bash
# ────────────────────────────────────────────────────────
# run_orchestrator.sh — launchd wrapper for coli-dev
# Создаёт директорию логов и запускает Python-оркестратор.
# ────────────────────────────────────────────────────────
DIR="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$HOME/Library/Logs/coli-dev"
exec "$DIR/.venv/bin/python" "$DIR/01_Projects/orchestrator.py"
