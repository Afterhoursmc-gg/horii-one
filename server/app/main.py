from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1.router import api_router
from app.core.config import settings
from app.core.logging import configure_logging
from app.database.base import Base
from app.database.session import engine


@asynccontextmanager
async def lifespan(_: FastAPI):
    # Development bootstrap; production will use Alembic migrations.
    if settings.app_env != "production":
        import app.database.models  # noqa: F401
        async with engine.begin() as connection:
            await connection.run_sync(Base.metadata.create_all)
    yield
    await engine.dispose()


def create_app() -> FastAPI:
    configure_logging()
    app = FastAPI(
        title="H0RII CORE",
        version="0.1.0",
        description="Backend/control plane for H0RII ONE iOS.",
        lifespan=lifespan,
    )
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    app.include_router(api_router, prefix="/api/v1")
    return app


app = create_app()
