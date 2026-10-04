# ColiDev for macOS

An early native SwiftUI client for the ColiDev learning platform. Open `ColiDev.xcodeproj` in Xcode on a Mac and run the `ColiDev` scheme.

## Included in this first slice

- Native macOS navigation for Today, Subjects, lesson sessions, and Settings.
- Russian and English interface and lesson content, switchable in the toolbar and persisted locally.
- Six subject starters: mathematics, English, physics, biology, zoology, and programming.
- One interactive practice module per subject: a live function graph, sentence builder, force/mass simulation, selectable cell diagram, animal adaptation explorer, and conditional-code runner.
- Immediate answer feedback and local completion progress.
- A lesson-aware RU/EN tutor connects to the existing local FastAPI orchestrator at 127.0.0.1:8000, displays SSE response chunks, and offers automatic or local-only routing.
- API keys stay in the server .env; the app contains no provider credentials. In automatic mode, lesson prompts may be sent to configured cloud providers. Local-only mode sends prompts to the Ollama endpoint configured by the server; verify that endpoint is on this Mac if on-device privacy is required.

## Current boundary

This is the beginning of implementation, not the complete product. The tutor uses the existing orchestrator, which can select local or configured cloud agents; its answers do not yet use RAG or web sources. The backend currently prepares the full answer before emitting SSE chunks, so cancelling the client stops receipt but may not stop provider work already underway. Account/sync, NotebookLM, direct Obsidian vault access, real video sourcing, and 3D assets need separate slices. The biology and zoology visual modules here are interactive 2D previews; they do not claim to be 3D lessons.

The project targets macOS 13+. This source has not been built on Xcode in the current Windows environment; a Mac build and runtime review remain necessary.
