# H0RII ONE

H0RII ONE is the native iOS personal assistant app.

Platform modules:

- `ios/` — **H0RII ONE**, native Swift/SwiftUI iPhone app.
- `server/` — **H0RII CORE**, permanent VPS backend/control plane.
- `web/` — **H0RII PWA**, installable web client / camera node / dashboard.
- `infrastructure/` — Docker, reverse proxy, TURN/WebRTC infrastructure.
- `docs/` — architecture, API, realtime, security notes.

Milestone 0 is the backend foundation: monorepo, FastAPI project, status endpoint, config, logging, Docker and tests.
