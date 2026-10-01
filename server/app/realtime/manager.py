class RealtimeManager:
    def __init__(self) -> None:
        self.active_connections: dict[str, object] = {}
