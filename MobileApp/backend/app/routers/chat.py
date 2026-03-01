from fastapi import APIRouter, Depends
import uuid
from datetime import datetime

from app.dependencies import get_current_user
from app.db.dynamodb import dynamodb
from app.services.bedrock_service import bedrock_service
from app.services.prompts import CHAT_ASSISTANT_PROMPT, VOICE_ASSISTANT_PROMPT
from app.models.chat import (
    ChatRequest,
    ChatResponse,
    VoiceQueryRequest,
    VoiceQueryResponse,
    ConversationHistory,
)

router = APIRouter()


def get_language_name(code: str) -> str:
    """Get full language name from code."""
    languages = {
        "en": "English",
        "hi": "Hindi",
        "ta": "Tamil",
        "te": "Telugu",
        "bn": "Bengali",
    }
    return languages.get(code, "Hindi")


@router.post("/message", response_model=ChatResponse)
async def send_message(
    request: ChatRequest,
    current_user: dict = Depends(get_current_user),
):
    """Send a chat message and get AI response."""
    phone = current_user["phone_number"]
    conversation_id = request.conversation_id or str(uuid.uuid4())
    
    # Get or create conversation
    conversation = dynamodb.get_conversation(phone, conversation_id)
    history = conversation.get("messages", []) if conversation else []
    
    # Build system prompt with user context
    system_prompt = CHAT_ASSISTANT_PROMPT.format(
        user_name=current_user.get("name", "User"),
        user_trade=current_user.get("primary_trade", "worker"),
        user_location=current_user.get("location", "India"),
        user_state=current_user.get("state", ""),
        language=get_language_name(request.language),
    )
    
    # Get AI response
    response_text = await bedrock_service.generate_response(
        prompt=request.message,
        system_prompt=system_prompt,
        conversation_history=history[-10:],  # Last 10 messages for context
    )
    
    # Save messages
    user_message = {
        "role": "user",
        "content": request.message,
        "timestamp": datetime.utcnow().isoformat(),
    }
    assistant_message = {
        "role": "assistant",
        "content": response_text,
        "timestamp": datetime.utcnow().isoformat(),
    }
    
    if conversation:
        dynamodb.add_message_to_conversation(phone, conversation_id, user_message)
        dynamodb.add_message_to_conversation(phone, conversation_id, assistant_message)
    else:
        dynamodb.create_conversation(
            phone, conversation_id, [user_message, assistant_message]
        )
    
    return ChatResponse(
        response=response_text,
        conversation_id=conversation_id,
        language=request.language,
    )


@router.get("/history")
async def get_history(
    current_user: dict = Depends(get_current_user),
    limit: int = 10,
):
    """Get user's conversation history."""
    phone = current_user["phone_number"]
    conversations = dynamodb.get_user_conversations(phone, limit)
    
    return {
        "conversations": [
            {
                "conversation_id": c["conversation_id"],
                "last_message": c["messages"][-1]["content"] if c.get("messages") else "",
                "message_count": len(c.get("messages", [])),
                "created_at": c.get("created_at"),
                "updated_at": c.get("updated_at"),
            }
            for c in conversations
        ]
    }


@router.post("/voice-query", response_model=VoiceQueryResponse)
async def voice_query(
    request: VoiceQueryRequest,
    current_user: dict = Depends(get_current_user),
):
    """Process a voice query and return response."""
    # Build system prompt
    system_prompt = VOICE_ASSISTANT_PROMPT.format(
        user_name=current_user.get("name", "User"),
        user_trade=current_user.get("primary_trade", "worker"),
        user_location=current_user.get("location", "India"),
        language=get_language_name(request.language),
        transcript=request.transcript,
    )
    
    # Get AI response
    response_text = await bedrock_service.generate_response(
        prompt=request.transcript,
        system_prompt=system_prompt,
        max_tokens=512,  # Shorter for voice responses
    )
    
    return VoiceQueryResponse(
        response=response_text,
        language=request.language,
    )
