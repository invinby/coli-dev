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
- API keys stay in the server `.env`; the app contains no provider credentials. In automatic mode, the question and retrieved course/Obsidian excerpts may be sent to configured cloud providers. Local-only mode sends them to the Ollama endpoint configured by the server; verify that endpoint is on this Mac if on-device privacy is required.

## Current boundary

This is the beginning of implementation, not the complete product. Local retrieval uses bounded lexical/BM25-style ranking; it is not semantic vector search, does not validate source authority, and does not fetch fresh web sources. A broad verified course library, web RAG, source-quality checks, NotebookLM workflow, direct vault browsing, real video sourcing, and 3D assets still need separate slices. The backend currently prepares the full answer before emitting SSE chunks, so cancelling the client stops receipt but may not stop provider work already underway. Account/sync also remains future work. The biology and zoology visual modules here are interactive 2D previews; they do not claim to be 3D lessons.

The project targets macOS 13+. This source has not been built on Xcode in the current Windows environment; a Mac build and runtime review remain necessary.
