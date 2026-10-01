from collections.abc import AsyncIterator


class MockAIProvider:
    async def generate(self, prompt: str) -> str:
        return "Hei! H0RII ONE-backenden fungerer."

    async def stream(self, prompt: str) -> AsyncIterator[str]:
        response = await self.generate(prompt)
        for token in response.split(" "):
            yield token + " "

    def supports_vision(self) -> bool:
        return False

    def supports_tools(self) -> bool:
        return False
