from fastapi import APIRouter, Depends
import uuid
import base64
from datetime import datetime

from app.dependencies import get_current_user
from app.db.dynamodb import dynamodb
from app.services.bedrock_service import bedrock_service
from app.services.gemini_service import gemini_service
from app.services.prompts import CHAT_ASSISTANT_PROMPT, VOICE_ASSISTANT_PROMPT, IMAGE_ANALYSIS_PROMPT
from app.models.chat import (
    ChatRequest,
    ChatResponse,
    ChatWithImageRequest,
    VoiceQueryRequest,
    VoiceQueryResponse,
    ConversationHistory,
)

router = APIRouter()


async def generate_ai_response(
    prompt: str,
    system_prompt: str,
    conversation_history=None,
    max_tokens: int = 1024,
) -> str:
    """Generate AI response with Bedrock primary, Gemini fallback."""
    try:
        # Try Bedrock first
        return await bedrock_service.generate_response(
            prompt=prompt,
            system_prompt=system_prompt,
            conversation_history=conversation_history,
            max_tokens=max_tokens,
        )
    except Exception as bedrock_error:
        print(f"Bedrock failed, trying Gemini fallback: {bedrock_error}")
        
        # Fallback to Gemini
        if gemini_service.is_available:
            return await gemini_service.generate_response(
                prompt=prompt,
                system_prompt=system_prompt,
                conversation_history=conversation_history,
                max_tokens=max_tokens,
            )
        else:
            raise Exception(f"Both Bedrock and Gemini unavailable. Bedrock error: {bedrock_error}")


def get_language_name(code: str) -> str:
    """Get full language name from code."""
    languages = {
        "en": "English",
        "hi": "Hindi",
        "mr": "Marathi",
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
    email = current_user["email"]
    conversation_id = request.conversation_id or str(uuid.uuid4())
    
    # Get or create conversation
    conversation = dynamodb.get_conversation(email, conversation_id)
    history = conversation.get("messages", []) if conversation else []
    
    # Build system prompt with user context
    system_prompt = CHAT_ASSISTANT_PROMPT.format(
        user_name=current_user.get("name", "User"),
        user_trade=current_user.get("primary_trade", "worker"),
        user_location=current_user.get("location", "India"),
        user_state=current_user.get("state", ""),
        language=get_language_name(request.language),
    )
    
    # Get AI response (Bedrock with Gemini fallback)
    response_text = await generate_ai_response(
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
        dynamodb.add_message_to_conversation(email, conversation_id, user_message)
        dynamodb.add_message_to_conversation(email, conversation_id, assistant_message)
    else:
        dynamodb.create_conversation(
            email, conversation_id, [user_message, assistant_message]
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
    email = current_user["email"]
    conversations = dynamodb.get_user_conversations(email, limit)
    
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


def _is_detailed_question(transcript: str) -> bool:
    """Check if the question requires a detailed response."""
    detailed_keywords = [
        "how to", "kaise", "explain", "batao", "process", "steps",
        "eligibility", "apply", "register", "documents", "required",
        "full details", "poora", "complete", "tell me about", "what is",
        "benefits", "fayde", "requirements", "zaroorat"
    ]
    transcript_lower = transcript.lower()
    return any(keyword in transcript_lower for keyword in detailed_keywords)


@router.post("/voice-query", response_model=VoiceQueryResponse)
async def voice_query(
    request: VoiceQueryRequest,
    current_user: dict = Depends(get_current_user),
):
    """Process a voice query and return response with conversation memory.
    
    If conversation_id is provided, loads history and maintains context.
    Otherwise creates new conversation.
    """
    email = current_user["email"]
    conv_id = request.conversation_id or str(uuid.uuid4())
    
    # Load conversation history if exists
    conversation = dynamodb.get_conversation(email, conv_id)
    history = conversation.get("messages", []) if conversation else []
    
    # Build system prompt with user context
    system_prompt = VOICE_ASSISTANT_PROMPT.format(
        user_name=current_user.get("name", "User"),
        user_trade=current_user.get("primary_trade", "worker"),
        user_location=current_user.get("location", "India"),
        user_state=current_user.get("state", ""),
        language="English" if request.language == "en" else "Hindi",
    )
    
    # Determine if this needs a detailed response
    needs_detail = _is_detailed_question(request.transcript)
    
    # Enhance prompt for detailed questions
    prompt = request.transcript
    if needs_detail:
        prompt = f"[GIVE A DETAILED 4-6 SENTENCE RESPONSE] {request.transcript}"
    
    # Get AI response with conversation history
    response_text = await generate_ai_response(
        prompt=prompt,
        system_prompt=system_prompt,
        conversation_history=history[-10:],  # Use last 10 messages for context
        max_tokens=500 if needs_detail else 200,
    )
    
    # Save messages to conversation history
    user_message = {
        "role": "user",
        "content": request.transcript,
        "timestamp": datetime.utcnow().isoformat(),
    }
    assistant_message = {
        "role": "assistant",
        "content": response_text,
        "timestamp": datetime.utcnow().isoformat(),
    }
    
    if conversation:
        dynamodb.add_message_to_conversation(email, conv_id, user_message)
        dynamodb.add_message_to_conversation(email, conv_id, assistant_message)
    else:
        dynamodb.create_conversation(email, conv_id, [user_message, assistant_message])
    
    return VoiceQueryResponse(
        response=response_text,
        language=request.language,
        conversation_id=conv_id,
    )


@router.post("/analyze-image", response_model=ChatResponse)
async def analyze_image(
    request: ChatWithImageRequest,
    current_user: dict = Depends(get_current_user),
):
    """Analyze an image and return AI response."""
    conversation_id = str(uuid.uuid4())
    
    # Build system prompt
    system_prompt = IMAGE_ANALYSIS_PROMPT.format(
        user_name=current_user.get("name", "User"),
        user_trade=current_user.get("primary_trade", "worker"),
        user_location=current_user.get("location", "India"),
        user_state=current_user.get("state", ""),
        language=get_language_name(request.language),
        user_message=request.message,
    )
    
    try:
        # Decode base64 image
        image_bytes = base64.b64decode(request.image_base64)
        
        # Analyze image using Bedrock
        result = await bedrock_service.analyze_image(
            image_bytes=image_bytes,
            prompt=request.message,
            system_prompt=system_prompt,
            max_tokens=2048,
            media_type=request.image_type,
        )
        
        # Extract response text
        if isinstance(result, dict):
            response_text = result.get("raw_response", str(result))
        else:
            response_text = str(result)
        
        return ChatResponse(
            response=response_text,
            conversation_id=conversation_id,
            language=request.language,
        )
        
    except Exception as e:
        print(f"Image analysis error: {e}")
        # Try Gemini fallback
        try:
            response_text = await gemini_service.analyze_image(
                image_bytes=base64.b64decode(request.image_base64),
                prompt=request.message,
                system_prompt=system_prompt,
                media_type=request.image_type,
            )
            return ChatResponse(
                response=response_text,
                conversation_id=conversation_id,
                language=request.language,
            )
        except Exception as fallback_error:
            print(f"Gemini fallback also failed: {fallback_error}")
            return ChatResponse(
                response=f"Sorry, I couldn't analyze the image. Please try again.",
                conversation_id=conversation_id,
                language=request.language,
            )
