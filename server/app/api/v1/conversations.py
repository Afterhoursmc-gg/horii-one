from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.ai.router import AIRouter
from app.auth.dependencies import require_device
from app.core.security import utcnow
from app.database.models import Conversation, Device, Message
from app.database.session import get_session

router = APIRouter(prefix="/conversations", tags=["conversations"])
ai_router = AIRouter()


class ConversationCreate(BaseModel):
    title: str = Field(default="New conversation", max_length=200)


class ConversationResponse(BaseModel):
    id: str
    title: str
    created_at: datetime
    updated_at: datetime


class MessageCreate(BaseModel):
    content: str = Field(min_length=1, max_length=20_000)


class MessageResponse(BaseModel):
    id: str
    conversation_id: str
    role: str
    content: str
    created_at: datetime


@router.post("", response_model=ConversationResponse, status_code=201)
async def create_conversation(
    payload: ConversationCreate,
    device: Device = Depends(require_device),
    session: AsyncSession = Depends(get_session),
) -> ConversationResponse:
    now = utcnow()
    conversation = Conversation(device_id=device.id, title=payload.title, created_at=now, updated_at=now)
    session.add(conversation)
    await session.commit()
    return ConversationResponse.model_validate(conversation, from_attributes=True)


@router.get("", response_model=list[ConversationResponse])
async def list_conversations(
    device: Device = Depends(require_device),
    session: AsyncSession = Depends(get_session),
) -> list[ConversationResponse]:
    result = await session.scalars(
        select(Conversation)
        .where(Conversation.device_id == device.id)
        .order_by(Conversation.updated_at.desc())
    )
    return [ConversationResponse.model_validate(item, from_attributes=True) for item in result]


@router.get("/{conversation_id}", response_model=list[MessageResponse])
async def get_messages(
    conversation_id: str,
    device: Device = Depends(require_device),
    session: AsyncSession = Depends(get_session),
) -> list[MessageResponse]:
    conversation = await session.scalar(
        select(Conversation).where(
            Conversation.id == conversation_id,
            Conversation.device_id == device.id,
        )
    )
    if conversation is None:
        raise HTTPException(status_code=404, detail="Conversation not found")
    result = await session.scalars(
        select(Message).where(Message.conversation_id == conversation.id).order_by(Message.created_at)
    )
    return [MessageResponse.model_validate(item, from_attributes=True) for item in result]


@router.post("/{conversation_id}/messages", response_model=list[MessageResponse], status_code=201)
async def create_message(
    conversation_id: str,
    payload: MessageCreate,
    device: Device = Depends(require_device),
    session: AsyncSession = Depends(get_session),
) -> list[MessageResponse]:
    conversation = await session.scalar(
        select(Conversation).where(
            Conversation.id == conversation_id,
            Conversation.device_id == device.id,
        )
    )
    if conversation is None:
        raise HTTPException(status_code=404, detail="Conversation not found")

    now = utcnow()
    user_message = Message(
        conversation_id=conversation.id,
        role="user",
        content=payload.content,
        created_at=now,
    )
    session.add(user_message)
    answer = await ai_router.generate(payload.content)
    assistant_message = Message(
        conversation_id=conversation.id,
        role="assistant",
        content=answer,
        created_at=utcnow(),
    )
    session.add(assistant_message)
    conversation.updated_at = assistant_message.created_at
    await session.commit()
    return [
        MessageResponse.model_validate(user_message, from_attributes=True),
        MessageResponse.model_validate(assistant_message, from_attributes=True),
    ]
