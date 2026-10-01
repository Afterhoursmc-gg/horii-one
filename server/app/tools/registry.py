from dataclasses import dataclass
from typing import Callable, Awaitable, Any


@dataclass(frozen=True)
class ToolDefinition:
    name: str
    description: str
    permission_level: str
    handler: Callable[[dict[str, Any]], Awaitable[dict[str, Any]]]


class ToolRegistry:
    def __init__(self) -> None:
        self._tools: dict[str, ToolDefinition] = {}

    def register(self, tool: ToolDefinition) -> None:
        self._tools[tool.name] = tool

    def get(self, name: str) -> ToolDefinition | None:
        return self._tools.get(name)
