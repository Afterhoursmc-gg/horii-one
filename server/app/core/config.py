from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    app_env: str = "development"
    service_name: str = "horii-core"
    version: str = "0.1.0"
    public_base_url: str = "http://localhost:8000"
    database_url: str = "sqlite+aiosqlite:///./horii_one_dev.db"
    redis_url: str = "redis://localhost:6379/0"
    secret_key: str = "dev-only-change-me"
    ai_provider: str = "mock"
    ai_api_key: str | None = None
    cors_origins: list[str] = ["http://localhost:5173", "http://127.0.0.1:5173"]


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
