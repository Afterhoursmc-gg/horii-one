# H0RII ONE

H0RII ONE is the native iOS personal assistant app.

Platform modules:

- `ios/` — **H0RII ONE**, native Swift/SwiftUI iPhone app.
- `server/` — **H0RII CORE**, permanent VPS backend/control plane.
- `web/` — **H0RII PWA**, installable web client / camera node / dashboard.
- `infrastructure/` — Docker, reverse proxy, TURN/WebRTC infrastructure.
- `docs/` — architecture, API, realtime, security notes.

Milestone 0 is the backend foundation: monorepo, FastAPI project, status endpoint, config, logging, Docker and tests.

Milestone 1 currently includes:

- Device registration at `POST /api/v1/auth/device`.
- Hashed bearer tokens with expiration and revocation.
- Authenticated `GET /api/v1/devices/me`.
- Conversation creation/listing/history.
- User message → `MockAIProvider` → stored assistant message.
- H0RII ONE SwiftUI/Xcode project copied into `ios/`.
- iOS `APIClient`, Keychain credential storage and CORE conversation UI scaffold.
- H0RII ONE chat can register the device, create a conversation and send messages to CORE.

The API client currently defaults to `https://api.horii.dev`; public CORE deployment and a real production URL are still pending. Local end-to-end REST verification is complete.
