from pydantic import BaseModel


class SmartDevice(BaseModel):
    id: str
    name: str
    type: str
    room: str | None = None
    capabilities: dict = {}
    state: dict = {}
    online: bool = False
