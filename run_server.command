#!/bin/bash
cd "$(dirname "$0")"
echo "=============================================="
echo "  🚀 ЗАПУСК COLI-DEV ORCHESTRATOR"
echo "=============================================="
echo "  🌐 http://127.0.0.1:8000"
echo "  🖥  http://127.0.0.1:8000/ui"
echo "  📋 http://127.0.0.1:8000/docs"
echo "=============================================="
echo ""
.venv/bin/python 01_Projects/orchestrator.py
echo ""
echo "Нажми Enter чтобы закрыть..."
read
