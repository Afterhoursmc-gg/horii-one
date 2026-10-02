import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine
from sqlalchemy.pool import StaticPool

from app.main import app
from app import database as _database  # noqa: F401
from app.database.base import Base
from app.database.session import get_session


@pytest.fixture
async def client():
    engine = create_async_engine(
        "sqlite+aiosqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    session_factory = async_sessionmaker(engine, expire_on_commit=False)
    async with engine.begin() as connection:
        await connection.run_sync(Base.metadata.create_all)

    async def override_session():
        async with session_factory() as session:
            yield session

    app.dependency_overrides[get_session] = override_session
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as test_client:
        yield test_client
    app.dependency_overrides.clear()
    await engine.dispose()


@pytest.mark.asyncio
async def test_device_to_conversation_pipeline(client: AsyncClient) -> None:
    registration = await client.post(
        "/api/v1/auth/device",
        json={
            "name": "H0RII ONE",
            "device_identifier": "test-ios-device-001",
            "device_type": "ios_native",
            "capabilities": {"microphone": True, "display": True},
        },
    )
    assert registration.status_code == 201
    credentials = registration.json()
    assert credentials["token"]

    headers = {"Authorization": f"Bearer {credentials['token']}"}
    me = await client.get("/api/v1/devices/me", headers=headers)
    assert me.status_code == 200
    assert me.json()["name"] == "H0RII ONE"
    assert me.json()["capabilities"]["microphone"] is True

    created = await client.post(
        "/api/v1/conversations",
        headers=headers,
        json={"title": "First H0RII conversation"},
    )
    assert created.status_code == 201
    conversation_id = created.json()["id"]

    message = await client.post(
        f"/api/v1/conversations/{conversation_id}/messages",
        headers=headers,
        json={"content": "Hei Horii"},
    )
    assert message.status_code == 201
    messages = message.json()
    assert [item["role"] for item in messages] == ["user", "assistant"]
    assert messages[1]["content"] == "Hei! H0RII ONE-backenden fungerer."

    history = await client.get(f"/api/v1/conversations/{conversation_id}", headers=headers)
    assert history.status_code == 200
    assert len(history.json()) == 2


@pytest.mark.asyncio
async def test_invalid_device_token_is_rejected(client: AsyncClient) -> None:
    response = await client.get(
        "/api/v1/devices/me",
        headers={"Authorization": "Bearer definitely-invalid"},
    )
    assert response.status_code == 401
