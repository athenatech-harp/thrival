# CLAUDE.md — Thrival Project Guide

## Project Overview

**thrival** is a personal wellness tracker consisting of two components:
- **iOS App**: Native Swift/SwiftUI app for data entry and visualization
- **Raspberry Pi Backend**: Local server for data storage, processing, and insights

The app tracks mood, anxiety, sleep quality, and behavioral patterns to help the user understand their mental and physical health over time.

## Repository State

This repository is in its **initial skeleton phase** (as of early 2026). Only the following exist:
- `README.md` — one-line project description
- `.gitignore` — Xcode/iOS-specific ignore rules

All source code, configuration, and infrastructure still need to be created.

## Planned Architecture

```
thrival/
├── ios/                    # Swift/SwiftUI iOS application
│   ├── thrival.xcodeproj   # Xcode project
│   ├── thrival/            # App source (Views, Models, Services)
│   └── thrivalTests/       # Unit and UI tests
├── backend/                # Raspberry Pi backend server
│   ├── src/                # Server source code
│   ├── tests/              # Backend tests
│   └── requirements.txt    # Python dependencies (or package.json for Node)
├── shared/                 # Shared data models/schemas (if applicable)
├── docs/                   # Architecture diagrams, API documentation
├── CLAUDE.md               # This file
└── README.md               # Project overview
```

> Update this section as the actual structure emerges.

## Technology Stack

### iOS App
- Language: **Swift**
- UI Framework: **SwiftUI** (preferred over UIKit for new code)
- Dependency manager: **Swift Package Manager** (CocoaPods and Carthage are in .gitignore but unused)
- Minimum target: TBD (set when Xcode project is created)

### Backend (Raspberry Pi)
- Runtime: TBD — likely **Python** (Flask/FastAPI) or **Node.js**
- Database: TBD — likely SQLite or InfluxDB for time-series wellness data
- Communication: local network HTTP/REST or MQTT

### Data Format
- JSON for API communication between iOS and backend
- Define a stable schema early and version it

## Git Workflow

### Branches
- `master` — stable, production-ready code
- `claude/<task-id>` — branches created by Claude AI for specific tasks (e.g. `claude/claude-md-mm5t7a90b48pz4oy-ofc6t`)
- Feature branches: `feature/<short-description>` for human-led work

### Commit Messages
- Use imperative mood: "Add sleep entry model" not "Added sleep entry model"
- Keep subject line under 72 characters
- Reference issue numbers where applicable: "Fix crash on mood save (#12)"

### Push Rules
- Claude AI branches must start with `claude/` — pushes to other branches will be rejected
- Always push with `-u`: `git push -u origin <branch-name>`

## Development Conventions

### Swift / iOS
- Follow [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)
- Use `camelCase` for variables and functions, `PascalCase` for types
- Prefer `struct` over `class` for data models (value semantics)
- Use `@StateObject` / `@ObservedObject` appropriately in SwiftUI
- Group files by feature, not by type (e.g., `Features/Mood/`, not `Models/`, `Views/`)
- Write unit tests for business logic; UI tests for critical user flows

### Backend (Python preferred)
- Follow **PEP 8** style guide
- Use type annotations throughout
- Keep route handlers thin; put logic in service/domain layer
- Use environment variables for configuration (never hardcode secrets)
- Write tests with `pytest`

### General
- No secrets or credentials committed to the repo
- Keep functions small and single-purpose
- Document non-obvious decisions with inline comments
- Prefer explicit over clever code

## Key Data Entities

These are the core wellness metrics to track (design models around them):

| Entity | Fields (initial) |
|---|---|
| MoodEntry | timestamp, mood_score (1–10), notes, tags |
| AnxietyEntry | timestamp, anxiety_level (1–10), triggers, notes |
| SleepEntry | date, bedtime, wake_time, quality_score (1–10), notes |
| BehavioralNote | timestamp, category, description |

## API Design (Backend)

When the backend is built, follow these conventions:
- RESTful endpoints: `GET /entries/mood`, `POST /entries/mood`, etc.
- Versioned API: `/api/v1/...`
- Return standard JSON envelopes: `{ "data": ..., "error": null }`
- Use ISO 8601 timestamps throughout

## Testing

### iOS
- Unit tests live in `thrivalTests/`
- Run tests via Xcode (`Cmd+U`) or `xcodebuild test`
- Aim for coverage on all model and service layers

### Backend
- Tests live in `backend/tests/`
- Run with `pytest` (Python) or `npm test` (Node)
- Include at least one integration test per API endpoint

## What to Build Next

When starting development, the recommended order is:

1. **Backend first** — set up the server, database schema, and REST API
2. **iOS data layer** — models, local persistence (Core Data or SwiftData)
3. **iOS networking** — connect to backend API
4. **iOS UI** — entry forms, history views, charts/visualizations
5. **CI/CD** — GitHub Actions for running tests on push

## Notes for AI Assistants

- This project is owned by a solo developer (athenatech-harp)
- Prefer **simple, readable solutions** over clever abstractions
- Avoid over-engineering; the scope is a personal tool, not a production SaaS
- When in doubt about architecture, ask before implementing
- Always run/verify tests before marking a task complete
- Keep commits atomic and well-described
- Update this CLAUDE.md whenever the architecture or conventions change significantly
