def can_execute(permission_level: str, device_id: str) -> bool:
    return permission_level == "safe"
