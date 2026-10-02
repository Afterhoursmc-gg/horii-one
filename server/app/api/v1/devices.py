from fastapi import APIRouter, Depends
from pydantic import BaseModel

from app.auth.dependencies import require_device
from app.database.models import Device

router = APIRouter(prefix="/devices", tags=["devices"])


class DeviceResponse(BaseModel):
    id: str
    name: str
    device_identifier: str
    device_type: str
    capabilities: dict
    presence: str


@router.get("/me", response_model=DeviceResponse)
async def get_current_device(device: Device = Depends(require_device)) -> DeviceResponse:
    return DeviceResponse(
        id=device.id,
        name=device.name,
        device_identifier=device.device_identifier,
        device_type=device.device_type,
        capabilities=device.capabilities or {},
        presence=device.presence,
    )
