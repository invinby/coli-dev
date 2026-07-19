# 🧬 coli-dev

**Гибридная ИИ-экосистема для изучения Python Backend**

Python Backend-разработка с AI-наставниками: Freebuff (Mimo 2.5) как главный архитектор и Claude Code (Gemini 2.5 Pro) как дебаггер.

---

## 🚀 Быстрый старт

```bash
# 1. Настрой API-ключи
cp .env.example .env
# Отредактируй .env — вставь свой GEMINI_API_KEY

# 2. Активируй окружение
source .venv/bin/activate

# 3. Запусти Claude Code
./start_claude.sh
```

## 📂 Структура

```
/
├── 01_Projects/        # Код проектов и домашки
├── 02_Areas/           # Учебные заметки
│   ├── Syntax_and_OOP/ # Python, ООП
│   ├── Databases_SQL/  # PostgreSQL
│   └── Django_FastAPI/ # Фреймворки
├── 03_Resources/       # Ресурсы и шпаргалки
├── .venv/              # Виртуальное окружение
├── .env                # 🔑 API-ключи (не коммитить!)
├── start_claude.sh     # Запуск Claude Code
└── ARCH_LOG.md         # Бортовой журнал
```

## 🧠 Агенты

| Модель | Роль | Задача |
|--------|------|--------|
| **Freebuff (Mimo 2.5)** | Архитектор | Проектирование, код-ревью, логика |
| **Claude Code (Gemini 2.5 Pro)** | Дебаггер | Баги, рефакторинг, 2M контекст |
| **Ollama (Qwen 3 Coder)** | Локальный Digital Twin | Офлайн-режим, проверка синтаксиса Python 3.13 |
