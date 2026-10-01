from fastapi import APIRouter
from pydantic import BaseModel

from app.core.config import settings

router = APIRouter()


class StatusResponse(BaseModel):
    status: str
    service: str
    version: str
    environment: str


@router.get("/status", response_model=StatusResponse)
async def get_status() -> StatusResponse:
    return StatusResponse(
        status="ok",
        service=settings.service_name,
        version=settings.version,
        environment=settings.app_env,
    )
