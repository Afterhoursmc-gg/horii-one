from app.tools.registry import ToolRegistry


class ToolExecutor:
    def __init__(self, registry: ToolRegistry) -> None:
        self.registry = registry

    async def execute(self, name: str, arguments: dict) -> dict:
        tool = self.registry.get(name)
        if tool is None:
            raise ValueError(f"Unknown tool: {name}")
        return await tool.handler(arguments)
