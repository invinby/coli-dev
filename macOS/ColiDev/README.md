# ColiDev for macOS

An early native SwiftUI client for the ColiDev learning platform. Open `ColiDev.xcodeproj` in Xcode on a Mac and run the `ColiDev` scheme.

## Included in this first slice

- Native macOS navigation for Today, Subjects, lesson sessions, and Settings.
- Russian and English interface and lesson content, switchable in the toolbar and persisted locally.
- Six subject starters: mathematics, English, physics, biology, zoology, and programming.
- One interactive practice module per subject: a live function graph, sentence builder, force/mass simulation, selectable cell diagram, animal adaptation explorer, and conditional-code runner.
- Immediate answer feedback and local completion progress.
- Starter lessons work offline. No cloud model or credentials are used by this preview.

## Current boundary

This is the beginning of implementation, not the complete product. The current Python AI orchestrator is not connected to the client yet; RAG, account/sync, NotebookLM, Obsidian vault access, real video sourcing, and 3D assets need separate audited slices. The biology and zoology visual modules here are interactive 2D previews; they do not claim to be 3D lessons.

The project targets macOS 13+. This source has not been built on Xcode in the current Windows environment; a Mac build and runtime review remain necessary.
