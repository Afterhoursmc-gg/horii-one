import hashlib
import secrets
from datetime import datetime, timedelta, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database.models import Device, DeviceToken


def generate_token() -> str:
    return secrets.token_urlsafe(48)


def hash_token(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


def expires_in(days: int = 30) -> datetime:
    return utcnow() + timedelta(days=days)


async def authenticate_token(session: AsyncSession, raw_token: str) -> Device | None:
    result = await session.execute(
        select(Device)
        .join(DeviceToken)
        .where(
            DeviceToken.token_hash == hash_token(raw_token),
            DeviceToken.revoked_at.is_(None),
            DeviceToken.expires_at > utcnow(),
            Device.revoked_at.is_(None),
        )
    )
    return result.scalar_one_or_none()
