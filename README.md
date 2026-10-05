# ColiDev

ColiDev is being built as a native macOS learning platform with a local Python backend. The current repository brings the ColiDev course idea and the earlier tutor/orchestrator code into one project. **The product is still under development; it is not a finished or bug-free release.** See the [macOS app notes](macOS/ColiDev/README.md) and [project plan](project-plan/README.md) for verified scope and remaining work.

## What exists now

- A SwiftUI macOS 13+ client with Russian and English, a starter lesson in mathematics, English, physics, biology, zoology, and programming, six interactive exercises, local lesson progress, and a lesson-aware tutor screen.
- A FastAPI backend with automatic and Ollama-local chat routes. Its current online debate flow calls configured Gemini and Moonshot APIs alongside Ollama; provider availability and actual account limits have not yet been verified end to end.
- An explicit, opt-in Google Search grounding path in Auto mode when a Gemini key is configured. It returns inline citations and Google's Search Suggestions directly; it bypasses local retrieval and agent debate, and is not saved to Obsidian.
- An offline SQLite index for Markdown in `02_Areas/` and Markdown/text cheat sheets in `03_Resources/Cheatsheets/`. It always supports lexical search and can add optional Ollama embeddings for semantic retrieval; vectors stay in the local SQLite database. Search results can cite file paths and line spans. Indexing metadata does not prove that course facts are current or verified.
- Local SQLite study-progress API for lesson review grades and SM-2-style spaced-repetition dates. Review writes are UUID-idempotent. Health/status, sessions, tutor chat, provider settings, progress, and Obsidian routes require a loopback caller and reject untrusted browser Origins when present.
- Six Russian/English curriculum roadmaps now cover foundations, intermediate topics, advanced topics, and practice ideas for mathematics, English, physics, biology, zoology, and programming. They are indexed by local RAG as outlines; they are not complete, source-verified courses.
- The macOS app bundles the same `02_Areas/` materials and now displays each priority subject's bilingual foundation-to-advanced roadmap before its starter lesson. The displayed roadmap remains an outline, not a completed course.
- The physics starter exercise includes an interactive SceneKit 3D view: orbit the block, adjust mass and force, and inspect the force vector and calculated acceleration. It is an explanatory visualization, not a full motion simulation; other starter exercises are still 2D.
- Optional Obsidian search and session-summary saving when its Local REST API is configured.
- GitHub Actions checks the backend suite and attempts a real Xcode macOS build after changes reach `main`.

## Still to build

Each of the six subjects has one interactive starter lesson plus an indexed curriculum roadmap from foundations through advanced topics; the roadmaps are outlines, not complete, source-verified courses. Local spaced repetition currently covers these six starter lessons; review scheduling is not yet connected to every roadmap module. Optional local semantic retrieval has been added but has not yet been validated against a live Ollama model. The opt-in Google Search path is a direct grounded answer, not a full web-RAG pipeline: trusted-source policy, web indexing/freshness controls, and combining web results with local course retrieval still need work. Course-quality review, NotebookLM support, a real video library, complete subject-specific 3D simulations, account/sync, and a verified model-routing policy are also incomplete. Google Search API use is gated by an 18+ confirmation, but eligibility and audience restrictions must be resolved before broad distribution: Google's current API terms limit use to people aged 18+ and professional or business use in supported regions. The remaining starter visual exercises are 2D; physics has one interactive 3D visualization prototype. See the project plan before treating a planned feature as implemented.

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

The server binds to `127.0.0.1:8000` by default. On macOS, start the backend and save Gemini, Kimi, and Obsidian credentials from Settings; the backend stores them in macOS Keychain. `.env` remains a development fallback and can also configure Ollama and other backend options. The course index, session state, study progress, and logs use per-user OS data/log directories; set `COLIDEV_DATA_DIR` to override app data and `COLIDEV_LOG_DIR` to override logs. For local-only chat, install Ollama, pull the model named by `OLLAMA_RESEARCHER`, and set `OLLAMA_URL` to `localhost`, `127.0.0.1`, or `::1`; the backend blocks non-loopback endpoints before sending the prompt. Optional semantic course search is disabled by default; set `OLLAMA_EMBEDDING_MODEL` (for example, `embeddinggemma`) to enable Ollama's local `/api/embed` route. Course text and vectors are sent only to the configured loopback Ollama endpoint, and lexical search remains available if embeddings are unset or unavailable. Obsidian Local REST API must also use a loopback URL. Automatic mode may send the learner's question and retrieved snippets to configured cloud providers. The separate Google Search option sends the current question and lesson context to Gemini/Google, uses its Search Suggestions and citations, and skips the ordinary agents, local retrieval, and Obsidian save path. Google stores grounding prompts, context, and output for up to 30 days; unpaid quota may be used to improve Google's services and processed by human reviewers. Search may consume quota or incur charges. Do not send sensitive information; API users must be 18 or older. The SwiftUI client does not start the backend automatically yet.

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
