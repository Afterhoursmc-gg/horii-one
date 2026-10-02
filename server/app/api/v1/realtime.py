import asyncio

from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from starlette.websockets import WebSocketState

from app.assistant.events import RealtimeEvent
from app.core.security import authenticate_token, utcnow
from app.database.session import AsyncSessionLocal
from app.realtime.manager import realtime_manager

router = APIRouter(tags=["realtime"])


@router.websocket("/realtime")
async def realtime_socket(websocket: WebSocket) -> None:
    token = websocket.query_params.get("token")
    if not token:
        await websocket.close(code=1008, reason="Bearer token required")
        return

    async with AsyncSessionLocal() as session:
        device = await authenticate_token(session, token)
        if device is None:
            await websocket.close(code=1008, reason="Invalid or expired token")
            return
        device.presence = "ONLINE"
        device.last_seen_at = utcnow()
        await session.commit()

    device_id = device.id
    await realtime_manager.connect(device_id, websocket)
    await websocket.send_json(
        RealtimeEvent(type="assistant.state", data={"state": "connected", "device_id": device_id}).model_dump(mode="json")
    )

    heartbeat = asyncio.create_task(_heartbeat(websocket))
    try:
        while True:
            message = await websocket.receive_json()
            event_type = message.get("type")
            if event_type == "heartbeat":
                await websocket.send_json(
                    RealtimeEvent(type="heartbeat", data={"ack": "true"}).model_dump(mode="json")
                )
            elif event_type == "device.presence":
                await websocket.send_json(
                    RealtimeEvent(type="device.state", data={"presence": message.get("data", {}).get("presence", "ONLINE")}).model_dump(mode="json")
                )
    except WebSocketDisconnect:
        pass
    finally:
        heartbeat.cancel()
        realtime_manager.disconnect(device_id, websocket)
        if websocket.client_state != WebSocketState.DISCONNECTED:
            await websocket.close()


async def _heartbeat(websocket: WebSocket) -> None:
    while True:
        await asyncio.sleep(25)
        await websocket.send_json(
            RealtimeEvent(type="heartbeat", data={"server": "true"}).model_dump(mode="json")
        )
