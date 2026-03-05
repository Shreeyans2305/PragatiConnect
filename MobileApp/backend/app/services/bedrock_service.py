import boto3
import json
import base64
from typing import Optional, List, Dict, Any
from app.config import settings


class BedrockService:
    """Service for interacting with Amazon Bedrock."""

    def __init__(self):
        self.client = boto3.client(
            "bedrock-runtime",
            region_name=settings.aws_region,
            aws_access_key_id=settings.aws_access_key_id,
            aws_secret_access_key=settings.aws_secret_access_key,
        )
        self.model_id = settings.bedrock_model_id
        # Detect if using Nova or Claude model
        self.is_nova = "nova" in self.model_id.lower()

    def _build_nova_request(
        self,
        messages: List[Dict],
        system_prompt: str,
        max_tokens: int,
        temperature: float,
    ) -> Dict:
        """Build request body for Amazon Nova models."""
        # Nova uses different message format
        nova_messages = []
        for msg in messages:
            content = msg.get("content", "")
            # Nova expects content as array of objects
            if isinstance(content, str):
                content = [{"text": content}]
            nova_messages.append({
                "role": msg["role"],
                "content": content
            })
        
        return {
            "inferenceConfig": {
                "maxTokens": max_tokens,
                "temperature": temperature,
            },
            "system": [{"text": system_prompt}] if system_prompt else [],
            "messages": nova_messages,
        }

    def _build_claude_request(
        self,
        messages: List[Dict],
        system_prompt: str,
        max_tokens: int,
        temperature: float,
    ) -> Dict:
        """Build request body for Anthropic Claude models."""
        return {
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": max_tokens,
            "temperature": temperature,
            "system": system_prompt,
            "messages": messages,
        }

    def _parse_nova_response(self, response_body: Dict) -> str:
        """Parse response from Nova models."""
        return response_body["output"]["message"]["content"][0]["text"]

    def _parse_claude_response(self, response_body: Dict) -> str:
        """Parse response from Claude models."""
        return response_body["content"][0]["text"]

    async def generate_response(
        self,
        prompt: str,
        system_prompt: str,
        conversation_history: Optional[List[Dict[str, str]]] = None,
        max_tokens: int = 1024,
        temperature: float = 0.7,
    ) -> str:
        """Generate a text response using Claude or Nova on Bedrock."""
        
        messages = []
        
        # Add conversation history
        if conversation_history:
            for msg in conversation_history:
                messages.append({
                    "role": msg["role"],
                    "content": msg["content"]
                })
        
        # Add current prompt
        messages.append({
            "role": "user",
            "content": prompt
        })

        # Build request based on model type
        if self.is_nova:
            request_body = self._build_nova_request(messages, system_prompt, max_tokens, temperature)
        else:
            request_body = self._build_claude_request(messages, system_prompt, max_tokens, temperature)

        try:
            response = self.client.invoke_model(
                modelId=self.model_id,
                body=json.dumps(request_body),
                contentType="application/json",
                accept="application/json",
            )
            
            response_body = json.loads(response["body"].read())
            
            # Parse response based on model type
            if self.is_nova:
                return self._parse_nova_response(response_body)
            else:
                return self._parse_claude_response(response_body)
        
        except Exception as e:
            print(f"Bedrock error: {e}")
            raise

    async def analyze_image(
        self,
        image_bytes: bytes,
        prompt: str,
        system_prompt: str,
        max_tokens: int = 2048,
        media_type: str = "image/jpeg",
    ) -> Dict[str, Any]:
        """Analyze an image using Claude or Nova Vision on Bedrock."""
        
        # Encode image to base64
        image_base64 = base64.b64encode(image_bytes).decode("utf-8")
        
        # Use the provided media type
        # media_type = "image/jpeg"  # Now passed as parameter

        if self.is_nova:
            # Nova vision format
            request_body = {
                "inferenceConfig": {
                    "maxTokens": max_tokens,
                },
                "system": [{"text": system_prompt}] if system_prompt else [],
                "messages": [
                    {
                        "role": "user",
                        "content": [
                            {
                                "image": {
                                    "format": media_type.split("/")[1],
                                    "source": {
                                        "bytes": image_base64,
                                    },
                                },
                            },
                            {
                                "text": prompt,
                            },
                        ],
                    }
                ],
            }
        else:
            # Claude vision format
            request_body = {
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": max_tokens,
                "system": system_prompt,
                "messages": [
                    {
                        "role": "user",
                        "content": [
                            {
                                "type": "image",
                                "source": {
                                    "type": "base64",
                                    "media_type": media_type,
                                    "data": image_base64,
                                },
                            },
                            {
                                "type": "text",
                                "text": prompt,
                            },
                        ],
                    }
                ],
            }

        try:
            response = self.client.invoke_model(
                modelId=self.model_id,
                body=json.dumps(request_body),
                contentType="application/json",
                accept="application/json",
            )
            
            response_body = json.loads(response["body"].read())
            
            # Parse response based on model type
            if self.is_nova:
                response_text = self._parse_nova_response(response_body)
            else:
                response_text = self._parse_claude_response(response_body)
            
            # Try to parse as JSON
            try:
                return json.loads(response_text)
            except json.JSONDecodeError:
                return {"raw_response": response_text}
        
        except Exception as e:
            print(f"Bedrock vision error: {e}")
            raise

    async def query_knowledge_base(
        self,
        query: str,
        knowledge_base_id: Optional[str] = None,
        max_results: int = 5,
    ) -> List[Dict[str, Any]]:
        """Query Knowledge Bases for Bedrock for RAG."""
        
        kb_id = knowledge_base_id or settings.bedrock_knowledge_base_id
        
        if not kb_id:
            return []
        
        try:
            kb_client = boto3.client(
                "bedrock-agent-runtime",
                region_name=settings.aws_region,
                aws_access_key_id=settings.aws_access_key_id,
                aws_secret_access_key=settings.aws_secret_access_key,
            )
            
            response = kb_client.retrieve(
                knowledgeBaseId=kb_id,
                retrievalQuery={"text": query},
                retrievalConfiguration={
                    "vectorSearchConfiguration": {
                        "numberOfResults": max_results
                    }
                },
            )
            
            results = []
            for result in response.get("retrievalResults", []):
                results.append({
                    "content": result.get("content", {}).get("text", ""),
                    "score": result.get("score", 0),
                    "metadata": result.get("metadata", {}),
                })
            
            return results
        
        except Exception as e:
            print(f"Knowledge base error: {e}")
            return []


# Singleton instance
bedrock_service = BedrockService()
