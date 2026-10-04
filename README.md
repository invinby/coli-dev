# ColiDev

ColiDev is being built as a native macOS learning platform with a local Python backend. The current repository brings the ColiDev course idea and the earlier tutor/orchestrator code into one project. **The product is still under development; it is not a finished or bug-free release.** See the [macOS app notes](macOS/ColiDev/README.md) and [project plan](project-plan/README.md) for verified scope and remaining work.

## What exists now

- A SwiftUI macOS 13+ client with Russian and English, a starter lesson in mathematics, English, physics, biology, zoology, and programming, six interactive 2D exercises, local lesson progress, and a lesson-aware tutor screen.
- A FastAPI backend with automatic and Ollama-local chat routes. Its current online debate flow calls configured Gemini and Moonshot APIs alongside Ollama; provider availability and actual account limits have not yet been verified end to end.
- An offline SQLite keyword index for Markdown in `02_Areas/` and Markdown/text cheat sheets in `03_Resources/Cheatsheets/`. Search results can cite file paths and line spans. Indexing metadata does not prove that course facts are current or verified.
- Optional Obsidian search and session-summary saving when its Local REST API is configured.
- GitHub Actions checks the backend suite and attempts a real Xcode macOS build after changes reach `main`.

## Still to build

The six subjects currently have starter content, not complete basic-to-advanced curricula. Source-checked web RAG, semantic search, course-quality review, NotebookLM support, a real video library, true interactive 3D lessons, account/sync, and a verified model-routing policy are not complete. The current visual exercises are 2D. See the project plan before treating a planned feature as implemented.

## Run the backend

Create a virtual environment, install the backend dependencies, copy `.env.example` to `.env`, and run the API from the repository root.

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements-orchestrator.txt
cp .env.example .env
python 01_Projects/orchestrator.py
```

On Windows PowerShell, use `py -3 -m venv .venv`, activate with `\.venv\Scripts\Activate.ps1`, and copy the template with `Copy-Item .env.example .env`.

The server binds to `127.0.0.1:8000` by default. On macOS, start the backend and save Gemini, Kimi, and Obsidian credentials from Settings; the backend stores them in macOS Keychain. `.env` remains a development fallback and can also configure Ollama and other backend options. For local-only chat, install Ollama, pull the model named by `OLLAMA_RESEARCHER`, and keep `OLLAMA_URL` pointed to a service on this Mac if the request must stay on-device. Automatic mode may send the learner's question and retrieved snippets to configured cloud providers. The SwiftUI client does not start the backend automatically yet.

## Open the macOS app

On a Mac with Xcode, open `macOS/ColiDev/ColiDev.xcodeproj`, select the `ColiDev` scheme, and run it. Start the backend separately using the steps above. A successful GitHub build verifies compilation only; it does not prove provider credentials, Obsidian, Ollama, or in-app behavior work on a user's Mac.

## Run backend checks

```bash
python -m pip install -r requirements-test.txt
python -m pytest 01_Projects -q
```

The tests use mocked provider calls. They do not consume API credits or verify live services.

## Configuration and private data

Keys saved from macOS Settings are stored in the system Keychain; their values are never returned to the client. `.env` is ignored by Git and remains a development fallback. Never commit real provider or Obsidian credentials. Keep the backend bound to loopback unless network exposure is deliberately designed and protected; the local service has no user-account authentication. The local database and lesson progress are stored on the user's device.

Earlier prototype launch scripts remain in the repository for reference; the native learning client uses `01_Projects/orchestrator.py` as its backend.
