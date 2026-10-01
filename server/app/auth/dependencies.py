from fastapi import HTTPException, status


async def require_device() -> str:
    raise HTTPException(status_code=status.HTTP_501_NOT_IMPLEMENTED, detail="Device auth pending")
