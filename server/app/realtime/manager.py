from collections import defaultdict
from typing import Any

from fastapi import WebSocket

from app.assistant.events import RealtimeEvent


class RealtimeManager:
    def __init__(self) -> None:
        self.active_connections: dict[str, set[WebSocket]] = defaultdict(set)

    async def connect(self, device_id: str, websocket: WebSocket) -> None:
        await websocket.accept()
        self.active_connections[device_id].add(websocket)

    def disconnect(self, device_id: str, websocket: WebSocket) -> None:
        connections = self.active_connections.get(device_id)
        if not connections:
            return
        connections.discard(websocket)
        if not connections:
            self.active_connections.pop(device_id, None)

    async def send(self, device_id: str, event: RealtimeEvent) -> None:
        dead: list[WebSocket] = []
        for websocket in self.active_connections.get(device_id, set()):
            try:
                await websocket.send_json(event.model_dump(mode="json"))
            except Exception:
                dead.append(websocket)
        for websocket in dead:
            self.disconnect(device_id, websocket)

    async def broadcast(self, event: RealtimeEvent) -> None:
        for device_id in list(self.active_connections):
            await self.send(device_id, event)


realtime_manager = RealtimeManager()
