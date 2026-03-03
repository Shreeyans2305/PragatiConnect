"""Gemini AI service for fallback when Bedrock is unavailable."""

import google.generativeai as genai
from typing import Optional, List, Dict, Any
from app.config import settings


class GeminiService:
    """Service for interacting with Google Gemini API."""

    def __init__(self):
        self.api_key = settings.gemini_api_key
        self.model = None
        self._initialized = False

    def _ensure_initialized(self):
        """Lazy initialization of Gemini client."""
        if not self._initialized and self.api_key:
            genai.configure(api_key=self.api_key)
            # Use gemini-2.0-flash-lite for better rate limits
            self.model = genai.GenerativeModel("gemini-2.0-flash-lite")
            self._initialized = True

    @property
    def is_available(self) -> bool:
        """Check if Gemini API is available."""
        return bool(self.api_key)

    async def generate_response(
        self,
        prompt: str,
        system_prompt: str,
        conversation_history: Optional[List[Dict[str, str]]] = None,
        max_tokens: int = 1024,
        temperature: float = 0.7,
    ) -> str:
        """Generate a text response using Gemini."""
        self._ensure_initialized()

        if not self.model:
            raise Exception("Gemini API key not configured")

        # Build the full prompt with system context and history
        full_prompt_parts = [f"System: {system_prompt}\n\n"]

        if conversation_history:
            for msg in conversation_history:
                role = "User" if msg["role"] == "user" else "Assistant"
                full_prompt_parts.append(f"{role}: {msg['content']}\n")

        full_prompt_parts.append(f"User: {prompt}\n\nAssistant:")

        full_prompt = "".join(full_prompt_parts)

        try:
            response = self.model.generate_content(
                full_prompt,
                generation_config=genai.types.GenerationConfig(
                    max_output_tokens=max_tokens,
                    temperature=temperature,
                ),
            )
            return response.text
        except Exception as e:
            print(f"Gemini error: {e}")
            raise

    async def analyze_image(
        self,
        image_bytes: bytes,
        prompt: str,
        system_prompt: str = "",
        max_tokens: int = 2048,
        media_type: str = "image/jpeg",
    ) -> str:
        """Analyze an image using Gemini Vision."""
        self._ensure_initialized()

        if not self.model:
            raise Exception("Gemini API key not configured")

        try:
            # Use vision model - same as main model which supports vision
            vision_model = genai.GenerativeModel("gemini-2.0-flash")

            # Create image part
            import base64
            image_data = base64.b64encode(image_bytes).decode("utf-8")
            
            response = vision_model.generate_content(
                [
                    f"{system_prompt}\n\n{prompt}" if system_prompt else prompt,
                    {"mime_type": media_type, "data": image_data}
                ],
                generation_config=genai.types.GenerationConfig(
                    max_output_tokens=max_tokens,
                ),
            )

            return response.text

        except Exception as e:
            print(f"Gemini vision error: {e}")
            raise


# Singleton instance
gemini_service = GeminiService()
