from fastapi import APIRouter

from app.api.v1 import auth, conversations, devices, realtime, status

api_router = APIRouter()
api_router.include_router(status.router, tags=["status"])
api_router.include_router(auth.router)
api_router.include_router(devices.router)
api_router.include_router(conversations.router)
api_router.include_router(realtime.router)
