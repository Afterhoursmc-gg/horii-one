class AssistantEngine:
    """Main orchestrator for future H0RII CORE assistant flows."""

    async def respond(self, message: str) -> str:
        return f"Hei! H0RII CORE mottok: {message}"
