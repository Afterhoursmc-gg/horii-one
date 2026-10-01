from app.ai.providers.mock import MockAIProvider


class AIRouter:
    def __init__(self) -> None:
        self.provider = MockAIProvider()

    async def generate(self, prompt: str) -> str:
        return await self.provider.generate(prompt)
