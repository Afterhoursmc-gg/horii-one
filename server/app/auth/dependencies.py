from typing import Annotated

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import hash_token, utcnow
from app.database.models import Device, DeviceToken
from app.database.session import get_session

bearer = HTTPBearer(auto_error=False)


async def require_device(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(bearer)],
    session: Annotated[AsyncSession, Depends(get_session)],
) -> Device:
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Bearer token required")

    token_hash = hash_token(credentials.credentials)
    result = await session.execute(
        select(Device)
        .join(DeviceToken)
        .where(
            DeviceToken.token_hash == token_hash,
            DeviceToken.revoked_at.is_(None),
            DeviceToken.expires_at > utcnow(),
            Device.revoked_at.is_(None),
        )
    )
    device = result.scalar_one_or_none()
    if device is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired device token")
    device.last_seen_at = utcnow()
    device.presence = "ONLINE"
    await session.commit()
    return device
