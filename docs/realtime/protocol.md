# Realtime Protocol

Endpoint:

```text
wss://<core-host>/api/v1/realtime?token=<device-token>
```

Authentication is required. The token is issued by `POST /api/v1/auth/device` and stored only in the native app Keychain.

Stable event envelope:

```json
{
  "type": "assistant.state",
  "id": "uuid",
  "timestamp": "2026-10-01T00:00:00Z",
  "data": {}
}
```

Implemented events:

- `assistant.state` on authenticated connection.
- `heartbeat` server ping and client acknowledgement.
- `device.state` presence response.

The iOS `HoriiWebSocketClient` reconnects with exponential backoff and jitter. Planned event families include assistant response streaming, tools, devices, camera, WebRTC signaling and smart-home state.
