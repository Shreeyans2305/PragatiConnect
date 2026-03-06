"""
Voice API Router.

Handles:
- POST /voice/query: Complete voice interaction (audio in -> AI response -> audio out)
- POST /voice/transcribe: Speech-to-Text only
- POST /voice/synthesize: Text-to-Speech only
"""

from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException
from typing import Optional
import base64
import uuid
from datetime import datetime

from app.dependencies import get_current_user
from app.db.dynamodb import dynamodb
from app.services.bedrock_service import bedrock_service
from app.services.speech_service import speech_service
from app.services.prompts import VOICE_ASSISTANT_PROMPT
from app.models.voice import (
    VoiceQueryRequest,
    VoiceQueryResponse,
    TranscribeRequest,
    TranscribeResponse,
    SynthesizeRequest,
    SynthesizeResponse,
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
        "mr": "Marathi",
        "gu": "Gujarati",
        "kn": "Kannada",
        "ml": "Malayalam",
        "pa": "Punjabi",
    }
    return languages.get(code, "Hindi")


@router.post("/query", response_model=VoiceQueryResponse)
async def voice_query(
    audio_file: UploadFile = File(...),
    language: str = Form("hi"),
    conversation_id: Optional[str] = Form(None),
    current_user: dict = Depends(get_current_user),
):
    """
    Complete voice interaction pipeline:
    1. Transcribe user's audio (Google STT)
    2. Send text to AI (AWS Bedrock Claude)
    3. Synthesize AI response to audio (Google TTS)
    
    Returns both text and audio response.
    """
    email = current_user["email"]
    conv_id = conversation_id or str(uuid.uuid4())

    try:
        # ===== Step 1: Speech-to-Text =====
        audio_data = await audio_file.read()
        
        # Determine audio encoding from content type
        encoding = "LINEAR16"  # Default
        if audio_file.content_type:
            if "ogg" in audio_file.content_type or "opus" in audio_file.content_type:
                encoding = "OGG_OPUS"
            elif "flac" in audio_file.content_type:
                encoding = "FLAC"
            elif "mp3" in audio_file.content_type:
                encoding = "MP3"

        stt_result = await speech_service.transcribe_audio(
            audio_data=audio_data,
            language_code=language,
            encoding=encoding,
        )

        user_text = stt_result["transcript"]
        
        if not user_text.strip():
            raise HTTPException(
                status_code=400,
                detail="Could not transcribe audio. Please speak clearly and try again.",
            )

        # ===== Step 2: AI Response (Bedrock) =====
        # Get conversation history
        conversation = dynamodb.get_conversation(email, conv_id)
        history = conversation.get("messages", []) if conversation else []

        # Build system prompt with user context
        language_name = get_language_name(language)
        system_prompt = VOICE_ASSISTANT_PROMPT.format(
            user_name=current_user.get("name", "User"),
            user_trade=current_user.get("primary_trade", "worker"),
            user_location=current_user.get("location", "India"),
            user_state=current_user.get("state", ""),
            language=language_name,
        )

        print(f"[VOICE] Language: {language} ({language_name}), User text: {user_text[:50]}...")

        # Add language reminder to user prompt
        enhanced_prompt = f"[User language: {language_name}] {user_text}"

        # Get AI response from Bedrock
        ai_response = await bedrock_service.generate_response(
            prompt=enhanced_prompt,
            system_prompt=system_prompt,
            conversation_history=history[-10:],
            temperature=0.7,
        )
        
        print(f"[VOICE] AI response (first 100 chars): {ai_response[:100]}...")
        print(f"[VOICE] Response length: {len(ai_response)} chars")

        # ===== Step 3: Text-to-Speech =====
        tts_result = await speech_service.synthesize_speech(
            text=ai_response,
            language_code=language,
            speaking_rate=0.95,  # Slightly slower for clarity
        )

        # ===== Save to conversation history =====
        user_message = {
            "role": "user",
            "content": user_text,
            "timestamp": datetime.utcnow().isoformat(),
            "type": "voice",
        }
        assistant_message = {
            "role": "assistant",
            "content": ai_response,
            "timestamp": datetime.utcnow().isoformat(),
            "type": "voice",
        }

        if conversation:
            dynamodb.add_message_to_conversation(email, conv_id, user_message)
            dynamodb.add_message_to_conversation(email, conv_id, assistant_message)
        else:
            dynamodb.create_conversation(email, conv_id, [user_message, assistant_message])

        return VoiceQueryResponse(
            user_transcript=user_text,
            ai_response=ai_response,
            audio_response=tts_result["audio_content"],
            audio_format=tts_result["audio_format"],
            conversation_id=conv_id,
            language=language,
            stt_confidence=stt_result.get("confidence", 0.0),
        )

    except HTTPException:
        raise
    except Exception as e:
        print(f"Voice query error: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Voice processing failed: {str(e)}",
        )


@router.post("/query-base64", response_model=VoiceQueryResponse)
async def voice_query_base64(
    request: VoiceQueryRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Voice query with base64 encoded audio (for mobile apps).
    Same pipeline as /query but accepts JSON with base64 audio.
    """
    email = current_user["email"]
    conv_id = request.conversation_id or str(uuid.uuid4())

    try:
        # Decode base64 audio
        audio_data = base64.b64decode(request.audio_data)

        # ===== Step 1: Speech-to-Text =====
        stt_result = await speech_service.transcribe_audio(
            audio_data=audio_data,
            language_code=request.language,
            encoding=request.audio_encoding or "LINEAR16",
            sample_rate_hertz=request.sample_rate or 16000,
        )

        user_text = stt_result["transcript"]

        if not user_text.strip():
            raise HTTPException(
                status_code=400,
                detail="Could not transcribe audio. Please speak clearly and try again.",
            )

        # ===== Step 2: AI Response =====
        conversation = dynamodb.get_conversation(email, conv_id)
        history = conversation.get("messages", []) if conversation else []

        language_name = get_language_name(request.language)
        system_prompt = VOICE_ASSISTANT_PROMPT.format(
            user_name=current_user.get("name", "User"),
            user_trade=current_user.get("primary_trade", "worker"),
            user_location=current_user.get("location", "India"),
            user_state=current_user.get("state", ""),
            language=language_name,
        )

        print(f"[VOICE-BASE64] Language: {request.language} ({language_name}), User text: {user_text[:50]}...")

        # Add language reminder to user prompt
        enhanced_prompt = f"[User language: {language_name}] {user_text}"

        ai_response = await bedrock_service.generate_response(
            prompt=enhanced_prompt,
            system_prompt=system_prompt,
            conversation_history=history[-10:],
        )
        
        print(f"[VOICE-BASE64] AI response (first 100 chars): {ai_response[:100]}...")
        print(f"[VOICE-BASE64] Response length: {len(ai_response)} chars")

        # ===== Step 3: Text-to-Speech =====
        tts_result = await speech_service.synthesize_speech(
            text=ai_response,
            language_code=request.language,
        )

        # Save conversation
        user_message = {
            "role": "user",
            "content": user_text,
            "timestamp": datetime.utcnow().isoformat(),
            "type": "voice",
        }
        assistant_message = {
            "role": "assistant",
            "content": ai_response,
            "timestamp": datetime.utcnow().isoformat(),
            "type": "voice",
        }

        if conversation:
            dynamodb.add_message_to_conversation(email, conv_id, user_message)
            dynamodb.add_message_to_conversation(email, conv_id, assistant_message)
        else:
            dynamodb.create_conversation(email, conv_id, [user_message, assistant_message])

        return VoiceQueryResponse(
            user_transcript=user_text,
            ai_response=ai_response,
            audio_response=tts_result["audio_content"],
            audio_format=tts_result["audio_format"],
            conversation_id=conv_id,
            language=request.language,
            stt_confidence=stt_result.get("confidence", 0.0),
        )

    except HTTPException:
        raise
    except Exception as e:
        print(f"Voice query error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/transcribe", response_model=TranscribeResponse)
async def transcribe_audio(
    audio_file: UploadFile = File(...),
    language: str = Form("hi"),
    current_user: dict = Depends(get_current_user),
):
    """
    Speech-to-Text only endpoint.
    Transcribes audio and returns text.
    """
    try:
        audio_data = await audio_file.read()

        result = await speech_service.transcribe_audio(
            audio_data=audio_data,
            language_code=language,
        )

        return TranscribeResponse(
            transcript=result["transcript"],
            confidence=result.get("confidence", 0.0),
            language=language,
            language_detected=result.get("language_detected"),
        )

    except Exception as e:
        print(f"Transcribe error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/transcribe-base64", response_model=TranscribeResponse)
async def transcribe_base64(
    request: TranscribeRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Speech-to-Text with base64 audio input.
    """
    try:
        audio_data = base64.b64decode(request.audio_data)

        result = await speech_service.transcribe_audio(
            audio_data=audio_data,
            language_code=request.language,
            encoding=request.audio_encoding or "LINEAR16",
            sample_rate_hertz=request.sample_rate or 16000,
        )

        return TranscribeResponse(
            transcript=result["transcript"],
            confidence=result.get("confidence", 0.0),
            language=request.language,
            language_detected=result.get("language_detected"),
        )

    except Exception as e:
        print(f"Transcribe error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/synthesize", response_model=SynthesizeResponse)
async def synthesize_speech(
    request: SynthesizeRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Text-to-Speech endpoint.
    Converts text to audio.
    """
    try:
        if not request.text or not request.text.strip():
            raise HTTPException(
                status_code=400,
                detail="Text cannot be empty",
            )
        
        print(f"[TTS] Synthesizing: text={request.text[:50]}..., language={request.language}")
        result = await speech_service.synthesize_speech(
            text=request.text,
            language_code=request.language,
            speaking_rate=request.speaking_rate or 1.0,
            pitch=request.pitch or 0.0,
            output_format=request.output_format or "MP3",
        )
        
        print(f"[TTS] Synthesis successful: format={result.get('audio_format')}, size={len(result.get('audio_content', ''))} chars")

        return SynthesizeResponse(
            audio_content=result["audio_content"],
            audio_format=result["audio_format"],
            language=request.language,
        )

    except HTTPException:
        raise
    except Exception as e:
        print(f"[ERROR] Synthesize error: {str(e)}")
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=500,
            detail=f"Text-to-Speech synthesis failed: {str(e)}"
        )
