# ColiDev for macOS

An early native SwiftUI client for the ColiDev learning platform. Open `ColiDev.xcodeproj` in Xcode on a Mac and run the `ColiDev` scheme.

## Included in this first slice

- Native macOS navigation for Today, Subjects, lesson sessions, and Settings.
- Russian and English interface and lesson content, switchable in the toolbar and persisted locally.
- Six subject starters: mathematics, English, physics, biology, zoology, and programming.
- Each current starter lesson separates the theory, mechanism, example, and limitations in Russian and English; the tutor receives all four blocks as lesson context.
- One interactive practice module per subject: a live function graph, sentence builder, force/mass simulation, selectable cell diagram, animal adaptation explorer, and conditional-code runner.
- Immediate answer feedback and local completion progress.
- A lesson-aware RU/EN tutor connects to the existing local FastAPI orchestrator at 127.0.0.1:8000, displays SSE response chunks, and offers automatic or local-only routing.
- The backend keeps an incremental SQLite keyword index of curated Markdown under `02_Areas/` and Markdown/text cheat sheets under `03_Resources/Cheatsheets/`. It refreshes changed files while handling tutor questions, searches locally without network access, and combines up to four course/Obsidian excerpts with `[K#]` citations.
- Retrieved course sources show their repository path, line span, filesystem modification time, and retrieval time separately. A modification time does not prove when facts were published or checked. The current Obsidian search response does not supply a reliable edit time, so the app labels that date unavailable.
- The database is stored per user (`~/Library/Application Support/coli-dev/knowledge.sqlite3` on macOS, `%LOCALAPPDATA%/ColiDev/knowledge.sqlite3` on Windows, or the XDG data directory on Linux). Backend `/health` reports the indexed-document count and last index check; Settings shows those values.
- Gemini, Kimi, and Obsidian API keys can be entered in Settings and are saved by the local backend to macOS Keychain. The backend reports only whether a key exists and where it came from; it never returns the value. `.env` remains a development fallback. In automatic mode, the question and retrieved course/Obsidian excerpts may be sent to configured cloud providers. Local-only mode sends them only to an Ollama endpoint on a loopback address; the backend blocks remote Ollama and Obsidian URLs.
- The tutor has a separate, opt-in Google Search action in Auto mode. After an 18+ confirmation, it sends the current question and lesson context directly to Gemini, shows inline citations and Google's Search Suggestions, and bypasses local retrieval and the other agents. This path does not save its answer to Obsidian. Google stores grounding prompts, context, and output for up to 30 days; unpaid quota may be used to improve Google's services and processed by human reviewers. Search may use quota or incur charges, so do not send sensitive information.

## Current boundary

This is the beginning of implementation, not the complete product. Local retrieval uses bounded lexical/BM25-style ranking; it is not semantic vector search and does not validate source authority. The optional direct Google Search path can ground one answer in current web results, but it is not an indexed web-RAG pipeline and does not combine those results with local retrieval. A broad verified course library, trusted-source and freshness controls, source-quality checks, NotebookLM workflow, direct vault browsing, real video sourcing, and 3D assets still need separate slices. The intended audience, use case, and supported regions must be settled before distribution: current Gemini API terms restrict use to people aged 18+ and professional or business use, and the in-app confirmation is not age verification. The backend currently prepares the full answer before emitting SSE chunks, so cancelling the client stops receipt but may not stop provider work already underway. Account/sync also remains future work. The biology and zoology visual modules here are interactive 2D previews; they do not claim to be 3D lessons.

The project targets macOS 13+. GitHub Actions successfully built the current source on a GitHub-hosted macOS 15 runner with Xcode 16.4 at commit `abf7472` ([build run](https://github.com/invinby/coli-dev/actions/runs/37230168823)). This verifies compilation only; the app has not yet been launched and exercised on a user's Mac, and live provider/Obsidian/Ollama behavior remains unverified.
