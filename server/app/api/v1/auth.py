from datetime import datetime

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.dependencies import require_device
from app.core.security import expires_in, generate_token, hash_token, utcnow
from app.database.models import Device, DeviceToken
from app.database.session import get_session

router = APIRouter(prefix="/auth", tags=["auth"])


class DeviceRegistrationRequest(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    device_identifier: str = Field(min_length=1, max_length=255)
    device_type: str = Field(default="ios_native", max_length=40)
    capabilities: dict = Field(default_factory=dict)


class DeviceRegistrationResponse(BaseModel):
    device_id: str
    token: str
    expires_at: datetime


@router.post("/device", response_model=DeviceRegistrationResponse, status_code=201)
async def register_device(
    payload: DeviceRegistrationRequest,
    session: AsyncSession = Depends(get_session),
) -> DeviceRegistrationResponse:
    existing = await session.scalar(
        select(Device).where(Device.device_identifier == payload.device_identifier)
    )
    now = utcnow()
    if existing is None:
        device = Device(
            name=payload.name,
            device_identifier=payload.device_identifier,
            device_type=payload.device_type,
            capabilities=payload.capabilities,
            presence="ONLINE",
            created_at=now,
            last_seen_at=now,
        )
        session.add(device)
        await session.flush()
    else:
        device = existing
        device.name = payload.name
        device.device_type = payload.device_type
        device.capabilities = payload.capabilities
        device.last_seen_at = now
        device.presence = "ONLINE"

    raw_token = generate_token()
    expires_at = expires_in()
    session.add(
        DeviceToken(
            device_id=device.id,
            token_hash=hash_token(raw_token),
            created_at=now,
            expires_at=expires_at,
        )
    )
    await session.commit()
    return DeviceRegistrationResponse(device_id=device.id, token=raw_token, expires_at=expires_at)


@router.post("/revoke", status_code=204)
async def revoke_current_device(
    device: Device = Depends(require_device),
    session: AsyncSession = Depends(get_session),
) -> None:
    device.revoked_at = utcnow()
    device.presence = "OFFLINE"
    await session.commit()
