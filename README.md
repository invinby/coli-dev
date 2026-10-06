# ColiDev

ColiDev is being built as a native macOS learning platform with a local Python backend. The current repository brings the ColiDev course idea and the earlier tutor/orchestrator code into one project. **The product is still under development; it is not a finished or bug-free release.** See the [macOS app notes](macOS/ColiDev/README.md) and [project plan](project-plan/README.md) for verified scope and remaining work.

## What exists now

- A SwiftUI macOS 13+ client with Russian and English, starter lessons across mathematics, English, physics, biology, zoology, and programming, linked modules including mathematics domain/range and programming variables/types and collections/loops, interactive exercises, local lesson progress, and a lesson-aware tutor screen.
- A FastAPI backend with automatic and Ollama-local chat routes. Ordinary Auto defaults to free-only routing: it may use the exact OpenRouter `openrouter/free` route when configured, and uses loopback Ollama for the other agent roles and fallbacks. The Control Center can set separate local Ollama models for draft, critic, and verifier roles, browse installed model IDs from the local Ollama service, and enter a custom model ID manually. The model catalog never queries a remote endpoint or downloads models; local-role preferences cannot switch those roles to a cloud provider. Paid cloud roles still require the global explicit cost-policy setting. Provider account limits are not guaranteed by this client.
- An explicit Google Search grounding path in Auto mode when a Gemini key is configured and the user has enabled potentially paid cloud calls in Control Center. It is blocked by default in both the UI and backend. When enabled, it searches the web without local retrieval; a separate, off-by-default choice can include up to four matching course/Obsidian excerpts in that one request. It returns inline citations and Google's Search Suggestions, bypasses agent debate, and is not saved to Obsidian.
- An offline SQLite index for Markdown in `02_Areas/` and Markdown/text cheat sheets in `03_Resources/Cheatsheets/`. It always supports lexical search and can add optional Ollama embeddings for semantic retrieval; vectors stay in the local SQLite database. Search results can cite file paths and line spans. Settings summarizes author-scheduled review reminders and materials without a declared review schedule; those counts do not verify that course facts are current or correct.
- The backend checks only fixed official-source URLs from lessons while it is running. The Control Center can show a plain-text preview of up to 4,000 characters from one approved page on demand, then record an explicit review for a selected lesson only after fetching the page again and confirming its digest still matches. The local ledger stores only the approved URL, lesson path, review date/time, and text fingerprint; it never stores the page excerpt or adds it to RAG. Local review history is bounded to the latest 10,000 events.
- Local SQLite study-progress API for lesson review grades and SM-2-style spaced-repetition dates. Review writes are UUID-idempotent. Health/status, sessions, tutor chat, provider settings, progress, and Obsidian routes require a loopback caller and reject untrusted browser Origins when present. HTTP request bodies are capped at 1 MiB before JSON parsing; tutor and Obsidian fields also have explicit length limits. The Obsidian bridge itself only accepts loopback destinations and validates/encodes vault-relative paths before constructing requests.
- Six Russian/English curriculum roadmaps now cover foundations, intermediate topics, advanced topics, and practice ideas for mathematics, English, physics, biology, zoology, and programming. They are indexed by local RAG as outlines; they are not complete, source-verified courses.
- The macOS app bundles the same `02_Areas/` materials and now displays each priority subject's bilingual foundation-to-advanced roadmap before its starter lesson. The displayed roadmap remains an outline, not a completed course.
- The physics starter exercise includes a two-second, one-dimensional motion experiment: set positive, zero, or negative net force and mass, then play, pause, reset, or step by 0.1 s. A SceneKit view uses a fixed metre scale; accessible readings show acceleration, signed velocity, displacement, and time. It models motion from rest under constant force without friction, not collisions or general rigid-body dynamics. Reduce Motion uses manual steps; changing parameters resets the experiment. Physical Mac acceptance is still required.
- Optional Obsidian search and session-summary saving when its Local REST API is configured. A lesson can also be saved as a separate, uniquely named Markdown copy in the local vault from its module page.
- GitHub Actions checks the backend suite and attempts a real Xcode macOS build after changes reach `main`.

## Still to build

The repository currently contains 21 bilingual lesson files across six subjects; this is a small starter set, not complete or academically reviewed courses. Local spaced repetition is connected to the six subject entry lessons, not every linked module. Optional local semantic retrieval has not yet been validated against a live Ollama model. The opt-in Google Search path can combine local course/Obsidian excerpts for one answer when the learner separately enables that choice; it is not a full web-RAG pipeline and can consume quota or incur charges. The same saved global cost policy now gates both ordinary Auto paid models and Google Search; both are blocked by default. Fixed-domain source monitoring, on-demand excerpt preview, per-lesson review records, and a paginated review-history viewer exist. Bounded source text enters web-RAG only for exact Python Tutorial and MedlinePlus Genetics DNA/gene basics pages whose reuse terms are documented; other monitored sources stay metadata-only. OpenStax sources are marked in the admin panel with their usual CC BY-NC-SA 4.0 restriction and stay uncached pending product-release rights review. Full course editing/revision, broader license-reviewed source indexing, and automatic editorial approval remain unimplemented. Native NotebookLM support exports a lesson to a local Markdown file for user-initiated import; direct API integration and sync are not implemented. Course-quality review, a real video library, complete subject-specific 3D simulations, and account/sync remain incomplete. Ordinary Auto has a free-only-by-default policy; provider availability and account limits can change. Google Search use is gated by an 18+ confirmation, but eligibility and audience restrictions must be resolved before broad distribution. The remaining starter visual exercises are 2D; physics has one interactive 3D visualization prototype. See the project plan before treating a planned feature as implemented.

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

The server binds to `127.0.0.1:8000` by default. The CI-built macOS `.app` includes a PyInstaller backend runtime and starts it when the app opens; an ordinary Xcode build from source still needs the backend started separately unless you package it with `macOS/ColiDev/scripts/package_backend_runtime.sh`. On macOS, save Gemini, Kimi, OpenRouter, and Obsidian credentials from the Control Center's Services pane; the backend stores them in macOS Keychain. `.env` remains a development fallback and can also configure Ollama and other backend options. The course index, session state, study progress, and logs use per-user OS data/log directories; set `COLIDEV_DATA_DIR` to override app data and `COLIDEV_LOG_DIR` to override logs. For local-only chat, install Ollama, pull the model named by `OLLAMA_RESEARCHER`, and set `OLLAMA_URL` to `localhost`, `127.0.0.1`, or `::1`; the backend blocks non-loopback endpoints before sending the prompt. Optional semantic course search is disabled by default; set `OLLAMA_EMBEDDING_MODEL` (for example, `embeddinggemma`) to enable Ollama's local `/api/embed` route. Course text and vectors are sent only to the configured loopback Ollama endpoint, and lexical search remains available if embeddings are unset or unavailable. Obsidian Local REST API must also use a loopback URL. Ordinary Auto blocks paid routes by default. Its cloud leg is limited to OpenRouter's exact `openrouter/free` route when its key is configured; otherwise Auto uses local Ollama. The global paid-route setting in Control Center explicitly allows configured potentially paid models and Google Search. Google Search sends the current question and lesson context to Gemini/Google and skips the ordinary agents and Obsidian save path; by default it skips local retrieval too. A second, off-by-default choice includes matching course/Obsidian excerpts in the Google request and displays an additional privacy warning. Google stores grounding prompts, context, and output for up to 30 days; unpaid quota may be used to improve Google's services and processed by human reviewers. Search may consume quota or incur charges. Do not send sensitive information; API users must be 18 or older.

## Open the macOS app

On a Mac with Xcode, open `macOS/ColiDev/ColiDev.xcodeproj`, select the `ColiDev` scheme, and run it. To test the backend-free launch path, build and package the local runtime using `requirements-macos-runtime.txt` and `macOS/ColiDev/scripts/package_backend_runtime.sh`. The GitHub workflow packages the backend and smoke-tests its API and tutor page; it does not launch the SwiftUI app or prove provider credentials, Obsidian, Ollama, or Keychain behavior on a user's Mac.

## Run backend checks

```bash
python -m pip install -r requirements-test.txt
python -m pytest 01_Projects -q
```

The tests use mocked provider calls. They do not consume API credits or verify live services.

## Configuration and private data

Keys saved from the macOS Control Center are stored in the system Keychain; their values are never returned to the client. `.env` is ignored by Git and remains a development fallback. Never commit real provider or Obsidian credentials. Keep the backend bound to loopback unless network exposure is deliberately designed and protected; the local service has no user-account authentication. The local database and lesson progress are stored on the user's device. The default cost policy gates potentially paid model routes and Google Search on the backend; allowing either requires explicitly saving the policy in Control Center.

Earlier prototype launch scripts remain in the repository for reference; the native learning client uses `01_Projects/orchestrator.py` as its backend.
