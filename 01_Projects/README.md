# ColiDev backend / Сервер ColiDev

`orchestrator.py` is the FastAPI service used by the native macOS app. It provides the local tutor API, model routing, lesson-progress storage, offline course search, and a loopback-only Obsidian bridge. `app.py` is an older sample and is not the app's backend.<br>
`orchestrator.py` — сервер FastAPI для нативного приложения macOS. Он обслуживает локального тьютора, маршрутизацию моделей, хранение прогресса, офлайн-поиск по курсам и локальную интеграцию с Obsidian. `app.py` — старый пример, он не является сервером приложения.

## Run locally / Локальный запуск

From the repository root, create a virtual environment, install the backend dependencies, and run the API on loopback.<br>
В корне репозитория создайте виртуальное окружение, установите зависимости сервера и запустите API только на локальном loopback-адресе.

macOS and Linux / macOS и Linux:

```sh
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements-orchestrator.txt
python -m uvicorn orchestrator:app --app-dir 01_Projects --host 127.0.0.1 --port 8000
```

Windows PowerShell / оболочка Windows PowerShell:

```powershell
py -3.12 -m venv .venv
.venv\Scripts\Activate.ps1
python -m pip install -r requirements-orchestrator.txt
python -m uvicorn orchestrator:app --app-dir 01_Projects --host 127.0.0.1 --port 8000
```

Use a virtual environment for development. Provider keys can be configured in the repository's `.env` file; on macOS, keys saved through the app are stored in Keychain. Keep the backend bound to `127.0.0.1` for local use.<br>
Для разработки используйте виртуальное окружение. Ключи провайдеров можно задать в файле `.env`; в macOS ключи, сохранённые через приложение, помещаются в Keychain. Для локального использования оставляйте сервер привязанным к `127.0.0.1`.

OpenRouter can serve as a cloud fallback for a specialist when direct Kimi is missing or unavailable. The `openrouter/free` route can select different free models over time; paid model IDs may incur charges. The Control Center also supports one configured OpenAI-compatible endpoint and model. That custom route is treated as potentially billable and remains disabled under the default free-only Auto policy. Remote custom endpoints must use HTTPS; HTTP is accepted only on loopback.<br>
OpenRouter может стать облачным запасным маршрутом для специалиста, если прямой Kimi не настроен или недоступен. Маршрут `openrouter/free` со временем может выбирать разные бесплатные модели; платные идентификаторы моделей могут привести к расходам. Центр управления также поддерживает один настраиваемый OpenAI-совместимый адрес и модель. Такой маршрут считается потенциально платным и выключен при стандартной бесплатной политике Auto. Для удалённых пользовательских адресов требуется HTTPS; HTTP разрешён только на loopback.

## Local knowledge index / Локальный индекс материалов

The offline index reads Markdown under `02_Areas/` and Markdown or text files under `03_Resources/Cheatsheets/`. It refreshes changed local files during tutor retrieval. Live Obsidian citations also include the note's filesystem modification time when its Local REST API supports metadata responses; this timestamp does not validate the note's claims. `POST /knowledge/refresh` rebuilds the local index on request; it does not fetch or verify external sources. SQLite data is kept in the user's application-support directory. `COLIDEV_DATA_DIR` can override the parent folder.<br>
Офлайн-индекс читает Markdown-файлы в `02_Areas/` и Markdown или текстовые файлы в `03_Resources/Cheatsheets/`. При поиске для тьютора он обновляет изменившиеся локальные файлы. В цитатах найденных заметок Obsidian также показывается время изменения файла, если Local REST API предоставляет метаданные; эта дата не проверяет утверждения заметки. Запрос `POST /knowledge/refresh` перестраивает индекс по команде, но не загружает и не проверяет внешние источники. База SQLite хранится в каталоге поддержки приложений пользователя; родительский каталог можно переопределить через `COLIDEV_DATA_DIR`.

Before returning tutor output, the backend checks that each `[K#]` marker refers to a source ID retrieved for that response. Unknown markers are replaced by a warning and returned as `citation_warnings` in the SSE `done` event. This confirms only that a source ID was retrieved; it does not prove source quality, factual accuracy, or support for the nearby claim.<br>
Перед возвратом ответа сервер проверяет, что каждая метка `[K#]` указывает на источник, найденный для этого ответа. Неизвестные метки заменяются предупреждением и возвращаются в событии SSE `done` в поле `citation_warnings`. Проверка подтверждает только наличие такого ID среди найденных источников; она не доказывает качество источника, точность факта или поддержку им конкретного утверждения.

## Provider usage / Учёт использования моделей

Successful Gemini, Kimi, OpenRouter, custom OpenAI-compatible, and Ollama responses are recorded in a separate per-user SQLite database. The loopback-only `GET /api/usage?days=30` reports model response counts and token counters only when the provider supplies them. Missing counters are not estimated, and charges are not calculated. Records are pruned after 90 days. Prompts, answers, and API keys are not stored. This view shows usage; it is not a provider invoice or an enforced token limit.<br>
Успешные ответы Gemini, Kimi, OpenRouter, пользовательских OpenAI-совместимых маршрутов и Ollama записываются в отдельную базу SQLite для текущего пользователя. Локальный запрос `GET /api/usage?days=30` показывает число ответов по моделям и счётчики токенов, только если провайдер их передал. Пропущенные счётчики не оцениваются, стоимость не рассчитывается. Записи удаляются через 90 дней. Промпты, ответы и API-ключи не хранятся. Эта панель показывает использование, но не является счётом провайдера или жёстким ограничителем токенов.

## Checks / Проверки

```sh
python -m pip install -r requirements-test.txt
python -m pytest 01_Projects -q
```

The suite mocks external AI providers and Obsidian. GitHub Actions also builds the macOS app for Apple Silicon and Intel, packages the Python backend, and smoke-checks its API. These checks do not replace running the app and its live integrations on a Mac.<br>
В тестах внешние ИИ-провайдеры и Obsidian заменены заглушками. GitHub Actions также собирает приложение macOS для Apple Silicon и Intel, упаковывает сервер Python и выполняет быстрые проверки его API. Эти проверки не заменяют запуск приложения и проверку настоящих интеграций на Mac.
