"""
Google Cloud Speech-to-Text and Text-to-Speech Service.

This service handles:
- Speech-to-Text (STT): Converting audio to text
- Text-to-Speech (TTS): Converting text to audio
"""

import base64
from typing import Optional, Dict, Any
from google.cloud import speech_v1p1beta1 as speech
from google.cloud import texttospeech
from app.config import settings


class SpeechService:
    """Service for Google Cloud Speech APIs."""

    def __init__(self):
        """Initialize Google Cloud clients."""
        # Clients will use GOOGLE_APPLICATION_CREDENTIALS env var
        # or explicit credentials if configured
        self._stt_client: Optional[speech.SpeechClient] = None
        self._tts_client: Optional[texttospeech.TextToSpeechClient] = None

    @property
    def stt_client(self) -> speech.SpeechClient:
        """Lazy initialization of Speech-to-Text client."""
        if self._stt_client is None:
            self._stt_client = speech.SpeechClient()
        return self._stt_client

    @property
    def tts_client(self) -> texttospeech.TextToSpeechClient:
        """Lazy initialization of Text-to-Speech client."""
        if self._tts_client is None:
            self._tts_client = texttospeech.TextToSpeechClient()
        return self._tts_client

    # Language code mappings for Google Cloud
    LANGUAGE_CODES = {
        "en": "en-IN",      # English (India)
        "hi": "hi-IN",      # Hindi
        "ta": "ta-IN",      # Tamil
        "te": "te-IN",      # Telugu
        "bn": "bn-IN",      # Bengali
        "mr": "mr-IN",      # Marathi
        "gu": "gu-IN",      # Gujarati
        "kn": "kn-IN",      # Kannada
        "ml": "ml-IN",      # Malayalam
        "pa": "pa-IN",      # Punjabi
    }

    # TTS Voice mappings (using Wavenet female voices for quality)
    # Female voice codes: A, C are typically female; B, D are typically male
    TTS_VOICES = {
        "en": ("en-IN-Wavenet-A", texttospeech.SsmlVoiceGender.FEMALE),  # Female English
        "hi": ("hi-IN-Wavenet-A", texttospeech.SsmlVoiceGender.FEMALE),  # Female Hindi
        "ta": ("ta-IN-Wavenet-A", texttospeech.SsmlVoiceGender.FEMALE),  # Female Tamil
        "te": ("te-IN-Standard-A", texttospeech.SsmlVoiceGender.FEMALE), # Female Telugu
        "bn": ("bn-IN-Wavenet-A", texttospeech.SsmlVoiceGender.FEMALE),  # Female Bengali
        "mr": ("mr-IN-Wavenet-A", texttospeech.SsmlVoiceGender.FEMALE),  # Female Marathi
        "gu": ("gu-IN-Wavenet-A", texttospeech.SsmlVoiceGender.FEMALE),  # Female Gujarati
        "kn": ("kn-IN-Wavenet-A", texttospeech.SsmlVoiceGender.FEMALE),  # Female Kannada
        "ml": ("ml-IN-Wavenet-A", texttospeech.SsmlVoiceGender.FEMALE),  # Female Malayalam
        "pa": ("pa-IN-Wavenet-A", texttospeech.SsmlVoiceGender.FEMALE),  # Female Punjabi
    }

    async def transcribe_audio(
        self,
        audio_data: bytes,
        language_code: str = "hi",
        encoding: str = "LINEAR16",
        sample_rate_hertz: int = 16000,
        enable_automatic_punctuation: bool = True,
    ) -> Dict[str, Any]:
        """
        Transcribe audio to text using Google Cloud Speech-to-Text.

        Args:
            audio_data: Raw audio bytes
            language_code: Language code (e.g., 'hi', 'en', 'ta')
            encoding: Audio encoding format
            sample_rate_hertz: Sample rate of the audio
            enable_automatic_punctuation: Add punctuation automatically

        Returns:
            Dict with transcript and confidence
        """
        # Map to Google Cloud language code
        gc_language_code = self.LANGUAGE_CODES.get(language_code, "hi-IN")

        # Configure recognition
        config = speech.RecognitionConfig(
            encoding=getattr(speech.RecognitionConfig.AudioEncoding, encoding),
            sample_rate_hertz=sample_rate_hertz,
            language_code=gc_language_code,
            enable_automatic_punctuation=enable_automatic_punctuation,
            model="latest_long",  # Best for long-form audio
            use_enhanced=True,    # Enhanced model for better accuracy
            # Alternative languages for multilingual speakers
            alternative_language_codes=[
                self.LANGUAGE_CODES.get("en", "en-IN"),
            ] if language_code != "en" else [],
        )

        audio = speech.RecognitionAudio(content=audio_data)

        try:
            response = self.stt_client.recognize(config=config, audio=audio)

            if not response.results:
                return {
                    "transcript": "",
                    "confidence": 0.0,
                    "language_detected": language_code,
                }

            # Get best result
            best_result = response.results[0]
            best_alternative = best_result.alternatives[0]

            return {
                "transcript": best_alternative.transcript,
                "confidence": best_alternative.confidence,
                "language_detected": gc_language_code,
                "words": [
                    {
                        "word": word.word,
                        "start_time": word.start_time.total_seconds(),
                        "end_time": word.end_time.total_seconds(),
                    }
                    for word in best_alternative.words
                ] if hasattr(best_alternative, 'words') else [],
            }

        except Exception as e:
            print(f"STT Error: {e}")
            raise

    async def transcribe_audio_streaming(
        self,
        audio_chunks: list,
        language_code: str = "hi",
        sample_rate_hertz: int = 16000,
    ) -> Dict[str, Any]:
        """
        Transcribe audio using streaming recognition for real-time results.

        Args:
            audio_chunks: List of audio data chunks
            language_code: Language code
            sample_rate_hertz: Sample rate

        Returns:
            Dict with final transcript
        """
        gc_language_code = self.LANGUAGE_CODES.get(language_code, "hi-IN")

        config = speech.StreamingRecognitionConfig(
            config=speech.RecognitionConfig(
                encoding=speech.RecognitionConfig.AudioEncoding.LINEAR16,
                sample_rate_hertz=sample_rate_hertz,
                language_code=gc_language_code,
                enable_automatic_punctuation=True,
            ),
            interim_results=True,
        )

        def request_generator():
            yield speech.StreamingRecognizeRequest(streaming_config=config)
            for chunk in audio_chunks:
                yield speech.StreamingRecognizeRequest(audio_content=chunk)

        try:
            responses = self.stt_client.streaming_recognize(request_generator())

            transcript = ""
            confidence = 0.0

            for response in responses:
                for result in response.results:
                    if result.is_final:
                        transcript = result.alternatives[0].transcript
                        confidence = result.alternatives[0].confidence

            return {
                "transcript": transcript,
                "confidence": confidence,
                "language_detected": gc_language_code,
            }

        except Exception as e:
            print(f"Streaming STT Error: {e}")
            raise

    async def synthesize_speech(
        self,
        text: str,
        language_code: str = "hi",
        speaking_rate: float = 1.0,
        pitch: float = 0.0,
        output_format: str = "MP3",
    ) -> Dict[str, Any]:
        """
        Convert text to speech using Google Cloud Text-to-Speech.

        Args:
            text: Text to synthesize
            language_code: Language code (e.g., 'hi', 'en')
            speaking_rate: Speed of speech (0.25 to 4.0, 1.0 is normal)
            pitch: Voice pitch (-20.0 to 20.0)
            output_format: Audio format (MP3, LINEAR16, OGG_OPUS)

        Returns:
            Dict with audio_content (base64), duration, etc.
        """
        gc_language_code = self.LANGUAGE_CODES.get(language_code, "hi-IN")
        voice_name, gender = self.TTS_VOICES.get(
            language_code, ("hi-IN-Wavenet-A", texttospeech.SsmlVoiceGender.FEMALE)
        )

        # Build synthesis input
        synthesis_input = texttospeech.SynthesisInput(text=text)

        # Voice configuration
        voice = texttospeech.VoiceSelectionParams(
            language_code=gc_language_code,
            name=voice_name,
            ssml_gender=gender,
        )

        # Audio configuration
        audio_encoding = {
            "MP3": texttospeech.AudioEncoding.MP3,
            "LINEAR16": texttospeech.AudioEncoding.LINEAR16,
            "OGG_OPUS": texttospeech.AudioEncoding.OGG_OPUS,
        }.get(output_format, texttospeech.AudioEncoding.MP3)

        audio_config = texttospeech.AudioConfig(
            audio_encoding=audio_encoding,
            speaking_rate=speaking_rate,
            pitch=pitch,
            # Effects profile for mobile playback
            effects_profile_id=["handset-class-device"],
        )

        try:
            response = self.tts_client.synthesize_speech(
                input=synthesis_input,
                voice=voice,
                audio_config=audio_config,
            )

            # Encode audio content to base64 for JSON transport
            audio_base64 = base64.b64encode(response.audio_content).decode("utf-8")

            return {
                "audio_content": audio_base64,
                "audio_format": output_format.lower(),
                "language": language_code,
                "text_length": len(text),
            }

        except Exception as e:
            print(f"TTS Error: {e}")
            raise

    async def synthesize_ssml(
        self,
        ssml: str,
        language_code: str = "hi",
        speaking_rate: float = 1.0,
    ) -> Dict[str, Any]:
        """
        Synthesize speech from SSML markup for more control.

        Args:
            ssml: SSML markup string
            language_code: Language code
            speaking_rate: Speech rate

        Returns:
            Dict with audio_content
        """
        gc_language_code = self.LANGUAGE_CODES.get(language_code, "hi-IN")
        voice_name, gender = self.TTS_VOICES.get(
            language_code, ("hi-IN-Wavenet-A", texttospeech.SsmlVoiceGender.FEMALE)
        )

        synthesis_input = texttospeech.SynthesisInput(ssml=ssml)

        voice = texttospeech.VoiceSelectionParams(
            language_code=gc_language_code,
            name=voice_name,
            ssml_gender=gender,
        )

        audio_config = texttospeech.AudioConfig(
            audio_encoding=texttospeech.AudioEncoding.MP3,
            speaking_rate=speaking_rate,
            effects_profile_id=["handset-class-device"],
        )

        try:
            response = self.tts_client.synthesize_speech(
                input=synthesis_input,
                voice=voice,
                audio_config=audio_config,
            )

            audio_base64 = base64.b64encode(response.audio_content).decode("utf-8")

            return {
                "audio_content": audio_base64,
                "audio_format": "mp3",
                "language": language_code,
            }

        except Exception as e:
            print(f"SSML TTS Error: {e}")
            raise


# Singleton instance
speech_service = SpeechService()
