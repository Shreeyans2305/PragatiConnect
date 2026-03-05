from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


class ChatMessage(BaseModel):
    """Single chat message."""
    role: str = Field(..., pattern=r"^(user|assistant)$")
    content: str
    timestamp: datetime = Field(default_factory=datetime.utcnow)


class ChatRequest(BaseModel):
    """Chat message request."""
    message: str = Field(..., min_length=1, max_length=4000)
    language: str = Field(default="hi", pattern=r"^(en|hi|mr|ta|te|bn|gu|pa)$")
    conversation_id: Optional[str] = None


class ChatWithImageRequest(BaseModel):
    """Chat message with image request."""
    message: str = Field(default="Please analyze this image.", max_length=4000)
    image_base64: str = Field(..., description="Base64 encoded image data")
    image_type: str = Field(default="image/jpeg", pattern=r"^image/(jpeg|png|gif|webp)$")
    language: str = Field(default="hi", pattern=r"^(en|hi|mr|ta|te|bn|gu|pa)$")


class ChatResponse(BaseModel):
    """Chat message response."""
    response: str
    conversation_id: str
    language: str


class VoiceQueryRequest(BaseModel):
    """Voice query request."""
    transcript: str = Field(..., min_length=1, max_length=2000)
    language: str = Field(default="hi", pattern=r"^(en|hi|mr|ta|te|bn|gu|pa)$")
    conversation_id: Optional[str] = None


class VoiceQueryResponse(BaseModel):
    """Voice query response."""
    response: str
    language: str
    conversation_id: str
    intent: Optional[str] = None


class ConversationSummary(BaseModel):
    """Conversation summary for history."""
    conversation_id: str
    last_message: str
    message_count: int
    created_at: datetime
    updated_at: datetime


class ConversationHistory(BaseModel):
    """Full conversation history."""
    conversation_id: str
    messages: List[ChatMessage]
    created_at: datetime
    updated_at: datetime
