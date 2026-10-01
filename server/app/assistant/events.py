from datetime import datetime, timezone
from uuid import uuid4
from pydantic import BaseModel, Field


class RealtimeEvent(BaseModel):
    type: str
    id: str = Field(default_factory=lambda: str(uuid4()))
    timestamp: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    data: dict = Field(default_factory=dict)
