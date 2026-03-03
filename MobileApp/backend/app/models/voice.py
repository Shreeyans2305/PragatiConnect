"""
Voice API Pydantic Models.
"""

from pydantic import BaseModel, Field
from typing import Optional


class VoiceQueryRequest(BaseModel):
    """Request for voice query with base64 audio."""
    audio_data: str = Field(..., description="Base64 encoded audio data")
    language: str = Field(default="hi", description="Language code (hi, en, ta, te, bn, mr)")
    conversation_id: Optional[str] = Field(None, description="Conversation ID for context")
    audio_encoding: Optional[str] = Field("LINEAR16", description="Audio encoding (LINEAR16, OGG_OPUS, FLAC, MP3)")
    sample_rate: Optional[int] = Field(16000, description="Audio sample rate in Hz")


class VoiceQueryResponse(BaseModel):
    """Response from voice query."""
    user_transcript: str = Field(..., description="Transcribed user speech")
    ai_response: str = Field(..., description="AI text response")
    audio_response: str = Field(..., description="Base64 encoded audio of AI response")
    audio_format: str = Field(..., description="Audio format (mp3, ogg_opus, linear16)")
    conversation_id: str = Field(..., description="Conversation ID")
    language: str = Field(..., description="Language used")
    stt_confidence: float = Field(0.0, description="STT confidence score")


class TranscribeRequest(BaseModel):
    """Request for speech-to-text only."""
    audio_data: str = Field(..., description="Base64 encoded audio data")
    language: str = Field(default="hi", description="Expected language")
    audio_encoding: Optional[str] = Field("LINEAR16", description="Audio encoding")
    sample_rate: Optional[int] = Field(16000, description="Sample rate in Hz")


class TranscribeResponse(BaseModel):
    """Response from transcription."""
    transcript: str = Field(..., description="Transcribed text")
    confidence: float = Field(0.0, description="Confidence score (0-1)")
    language: str = Field(..., description="Requested language")
    language_detected: Optional[str] = Field(None, description="Detected language code")


class SynthesizeRequest(BaseModel):
    """Request for text-to-speech."""
    text: str = Field(..., description="Text to synthesize")
    language: str = Field(default="hi", description="Language code")
    speaking_rate: Optional[float] = Field(1.0, description="Speech rate (0.25-4.0)")
    pitch: Optional[float] = Field(0.0, description="Voice pitch (-20 to 20)")
    output_format: Optional[str] = Field("MP3", description="Output format (MP3, LINEAR16, OGG_OPUS)")


class SynthesizeResponse(BaseModel):
    """Response from speech synthesis."""
    audio_content: str = Field(..., description="Base64 encoded audio")
    audio_format: str = Field(..., description="Audio format")
    language: str = Field(..., description="Language synthesized")
