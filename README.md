# 🧬 coli-dev

**Гибридная ИИ-экосистема для изучения Python Backend**

AI-ассистенты для коддинга: Kimi K3 (Kimi Code), Gemini 3.5 Flash (Claude Code) и полный консилиум.

---

## 🚀 Быстрый старт

```bash
# 1. Настрой API-ключи
cp .env.example .env
# Отредактируй .env — вставь ключи:
#   KIMI_API_KEY    → https://platform.kimi.ai/
#   GEMINI_API_KEY  → https://aistudio.google.com/app/apikey

# 2. Запусти единое меню
bash start.sh
```

## 📋 Режимы запуска

### 1. 🦊 Kimi Code (Kimi K3)
```bash
bash start_kimi_code.sh
# или через меню: bash start.sh → выбор 1
```
- **Модель:** Kimi K3 (moonshot-v1-auto)
- **Провайдер:** Moonshot AI (напрямую)
- **Ключ:** `KIMI_API_KEY`

### 2. 🤖 Claude Code (Gemini 3.5 Flash)
```bash
bash start_claude.sh
# или через меню: bash start.sh → выбор 2
```
- **Модель:** Gemini 3.5 Flash
- **Провайдер:** Google AI Studio (напрямую через LiteLLM)
- **Ключ:** `GEMINI_API_KEY`

### 3. 🧠 Консилиум (полная архитектура)
```bash
bash start_v4.sh
# или через меню: bash start.sh → выбор 3
```
- **Включает:**
  - 👑 Kimi K3 — Верховный Судья
  - ⚡ Gemini 3.5 Flash — Генератор
  - 🔮 GLM 5.2 — Генератор
  - 🦊 Freebuff (Mimo 2.5) — Критик
  - 🐉 Qwen 2.5 Coder — Верификатор
- **Веб-интерфейс:** http://127.0.0.1:8000

### 4. 🌐 Оркестратор (API)
```bash
bash start_v4.sh
```
- **API эндпоинты:**
  - `POST /chat/stream` — чат с SSE
  - `GET /api/status` — статус системы
  - `GET /health` — проверка здоровья
  - `GET /docs` — Swagger документация (DEV_MODE)

## 📂 Структура

```
/
├── 01_Projects/        # Код проектов и API
├── 02_Areas/           # Учебные заметки
├── 03_Resources/       # Ресурсы и шпаргалки
├── .env                # 🔑 API-ключи (не коммитить!)
├── .env.example        # Шаблон ключей
├── start.sh            # 🎯 Единое меню запуска
├── start_kimi_code.sh  # 🦊 Kimi Code
├── start_claude.sh     # 🤖 Claude Code
├── start_v4.sh         # 🧠 Консилиум + API
└── ARCH_LOG.md         # Бортовой журнал
```

## 🔑 API-ключи

| Ключ | Где получить | Используется для |
|------|--------------|------------------|
| `KIMI_API_KEY` | https://platform.kimi.ai/ | Kimi Code, Верховный Судья |
| `GEMINI_API_KEY` | https://aistudio.google.com/app/apikey | Claude Code, Генераторы |
| `OPENROUTER_API_KEY` | https://openrouter.ai/keys | Freebuff (Mimo 2.5) |
| `ZHIPU_API_KEY` | https://open.bigmodel.cn/ | GLM 5.2 (опционально) |
| `OBSIDIAN_API_KEY` | Obsidian → Настройки → Remote API | Автосохранение сессий |

## 🧠 Архитектура

```
УРОВЕНЬ 1: Генераторы + Верховный Судья
├─ Gemini 3.5 Flash  → черновик
├─ GLM 5.2           → черновик
└─ Kimi K3 (судья)   → консенсус

УРОВЕНЬ 2: Локальный Критик
├─ Freebuff (Mimo 2.5)   → код-ревью
├─ Qwen 2.5 Coder 7B     → верификация
└─ Финальный ответ
```

## ⚡ Команды

```bash
# Единое меню
bash start.sh

# Напрямую
bash start_kimi_code.sh   # Kimi K3
bash start_claude.sh      # Gemini 3.5 Flash
bash start_v4.sh          # Консилиум + API

# Тесты
python check_all.py       # Проверка конфигурации
```
