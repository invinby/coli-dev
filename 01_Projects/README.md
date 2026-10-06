# ColiDev backend

`orchestrator.py` is the FastAPI service used by the native macOS client. It provides the local tutor API, provider routing, lesson-progress storage, the offline course index, and the loopback-only Obsidian bridge. `app.py` is an earlier minimal FastAPI sample and is not the application backend.

## Run locally

From the repository root, install the backend dependencies and start the service on loopback.

macOS/Linux:

```sh
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements-orchestrator.txt
python -m uvicorn orchestrator:app --app-dir 01_Projects --host 127.0.0.1 --port 8000
```

Windows PowerShell:

```powershell
py -3.12 -m venv .venv
.venv\Scripts\Activate.ps1
python -m pip install -r requirements-orchestrator.txt
python -m uvicorn orchestrator:app --app-dir 01_Projects --host 127.0.0.1 --port 8000
```

Use a Python virtual environment for development. Optional provider keys can be configured through the repository `.env` file; on macOS, keys entered in the app Settings are stored in Keychain. Keep the service bound to `127.0.0.1` for local use. OpenRouter is a fallback cloud specialist when direct Kimi is missing or unavailable; the default `openrouter/free` route can select different free models over time, and paid model IDs may incur charges. Control Center also supports one user-configured OpenAI-compatible endpoint and model for specialist/final routes. Its key is stored under `OPENAI_COMPATIBLE_API_KEY` in Keychain; its HTTPS base URL and model ID are stored locally. Remote endpoints must use HTTPS; HTTP is accepted only for loopback. This custom route is treated as potentially billable and is disabled by the default free-only Auto policy.

## Local knowledge index

The offline index scans Markdown under `02_Areas/` and Markdown/text under `03_Resources/Cheatsheets/`. It refreshes changed files during tutor retrieval. Settings also exposes `POST /knowledge/refresh` to rebuild the local index on demand; this reads bundled local materials and does not fetch or verify external sources. The SQLite database is stored in the user's application-support directory, with `COLIDEV_DATA_DIR` available as an override.

Before tutor answers are streamed, the backend verifies that each `[K#]` marker refers to an ID in that response's retrieved local sources. Unknown markers are replaced with an explicit unavailable-source note and returned as `citation_warnings` in the SSE `done` event. This confirms only that a source ID was retrieved; it does not verify source quality, factual correctness, or whether the source supports the associated claim.

## Provider usage records

Successful Gemini, Kimi, OpenRouter, custom OpenAI-compatible, and Ollama responses are recorded in a separate per-user SQLite database (`provider-usage.sqlite3`). The loopback-only `GET /api/usage?days=30` reports model response counts and token counters only when the provider returns them; it does not estimate missing counters or calculate charges. Records are pruned after 90 days. Prompts, answers, and API keys are not stored. This is usage visibility, not a provider billing statement or an enforced token budget.

## Tests

```sh
python -m pip install -r requirements-test.txt
python -m pytest 01_Projects -q
```

The suite mocks external AI providers and Obsidian. GitHub Actions also builds the macOS app on Apple Silicon and Intel runners, embeds the Python backend, and smoke-tests the bundled API. These checks do not replace running the app and its live provider integrations on a Mac.
