# ColiDev for macOS

An early native SwiftUI client for the ColiDev learning platform. Open `ColiDev.xcodeproj` in Xcode on a Mac and run the `ColiDev` scheme.

## Included in this first slice

- Native macOS navigation for Today, Subjects, lesson sessions, and Settings.
- Russian and English interface and lesson content, switchable in the toolbar and persisted locally.
- Six subject starters: mathematics, English, physics, biology, zoology, and programming.
- One interactive practice module per subject: a live function graph, sentence builder, force/mass simulation, selectable cell diagram, animal adaptation explorer, and conditional-code runner.
- Immediate answer feedback and local completion progress.
- A lesson-aware RU/EN tutor connects to the existing local FastAPI orchestrator at 127.0.0.1:8000, displays SSE response chunks, and offers automatic or local-only routing.
- The tutor retrieves a small set of live excerpts from the connected Obsidian vault, adds source markers to its context, and shows the note paths and snippets under the answer. It does not yet keep an independent offline index or retrieve web sources.
- API keys stay in the server .env; the app contains no provider credentials. In automatic mode, the question and retrieved Obsidian excerpts may be sent to configured cloud providers. Local-only mode sends them to the Ollama endpoint configured by the server; verify that endpoint is on this Mac if on-device privacy is required.

## Current boundary

This is the beginning of implementation, not the complete product. The tutor has an initial Obsidian retrieval slice, but it does not yet have an independent local index, web RAG, per-note edit-date tracking, or a broad verified course library. The backend currently prepares the full answer before emitting SSE chunks, so cancelling the client stops receipt but may not stop provider work already underway. Account/sync, NotebookLM, direct vault browsing, real video sourcing, and 3D assets need separate slices. The biology and zoology visual modules here are interactive 2D previews; they do not claim to be 3D lessons.

The project targets macOS 13+. This source has not been built on Xcode in the current Windows environment; a Mac build and runtime review remain necessary.
